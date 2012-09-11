require "#{Rails.root}/lib/import_helpers.rb"
require "#{Rails.root}/lib/spreadsheet_helpers.rb"
require "#{Rails.root}/lib/address_helpers.rb"

include ImportHelpers
include SpreadsheetHelpers
include AddressHelpers
require 'rubyXL'

namespace :foreclosures do
  desc "Downloading CDC case numbers from s3.amazon.com"  
  task :load_sheriff, [:cdc_number] => :environment  do |t, args|

    downloaded_file_path = "#{Rails.root}/lib/assets/Sheriff/Writs Filed - Code Enforcement.xlsx"


      workbook = RubyXL::Parser.parse(downloaded_file_path)
      sheet = workbook.worksheets[0].extract_data
      cdc_col = 3
      addr_col = 0
      client = Savon.client ENV['SHERIFF_WSDL']
      sheet.each do |row|

        if row[cdc_col]
          cdc_number = row[cdc_col]
          address_long = row[addr_col]
          puts "address_long => " << row.to_s
          if cdc_number && cdc_number != "CDC ID"
            response = client.request 'm:GetForeclosure' do 
              http.headers['SOAPAction'] = ENV['SHERIFF_ACTION']
              soap.namespaces['xmlns:m'] = ENV['SHERIFF_NS']
              soap.body = {'m:cdcCaseNumber' => cdc_number, 'm:key' => ENV['SHERIFF_PASSWORD'] }
            end
            
            foreclosure = response.hash[:envelope][:body][:get_foreclosure_response][:get_foreclosure_result][:foreclosure]

            sale_dt = nil
            unless foreclosure[:sale_date] == "Null"
              sale_dt = DateTime.strptime(foreclosure[:sale_date], '%m/%d/%Y %H:%M:%S %p')
            end
            Foreclosure.create(address_long: address_long, status: foreclosure[:sale_status], notes: "", sale_date: sale_dt, title: foreclosure[:case_title], cdc_case_number: foreclosure[:cdc_case_number], defendant: foreclosure[:defendant], plaintiff: foreclosure[:plaintiff], house_num: foreclosure[:property_address])#, street_name: addr[:street_name], street_type: addr[:street_type], 
          end
        end
      end
    puts "foreclosures:load_sheriff"
  end

  desc "Correlate foreclosure data with addresses"  
  task :match => :environment  do |t, args|
    # go through each foreclosure
    success = 0
    failure = 0

    Foreclosure.where('address_id is null').each do |row|
      # compare each address in demo list to our address table
      #address = Address.where("address_long LIKE ?", "%#{row.address_long}%")
      address = AddressHelpers.find_address(row.address_long)

      unless (address.empty?)
        Foreclosure.find(row.id).update_attributes(:address_id => address.first.id)      
        success += 1
      else
        puts "#{row.address_long} address not found in address table"
        failure += 1
      end
    end
    puts "There were #{success} successful matches and #{failure} failed matches"      
  end

  desc "Delete all foreclosures from database"
  task :drop => :environment  do |t, args|
    Foreclosure.destroy_all
  end
end
