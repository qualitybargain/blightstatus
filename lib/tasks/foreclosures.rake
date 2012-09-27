require "#{Rails.root}/lib/import_helpers.rb"
require "#{Rails.root}/lib/spreadsheet_helpers.rb"
require "#{Rails.root}/lib/address_helpers.rb"
require "#{Rails.root}/lib/abatement_helpers.rb"
require 'rubyXL'

include ImportHelpers
include SpreadsheetHelpers
include AddressHelpers
include AbatementHelpers


namespace :foreclosures do
  desc "Downloading CDC case numbers from s3.amazon.com"  
  task :load_writfile, [:file_name, :bucket_name] => :environment  do |t, args|
    
    args.with_defaults(:bucket_name => "neworleansdata", :file_name => "Writs Filed - Code Enforcement.xlsx")  
    p args

    #connect to amazon
    ImportHelpers.connect_to_aws
    s3obj = AWS::S3::S3Object.find args.file_name, args.bucket_name
    downloaded_file_path = ImportHelpers.download_from_aws(s3obj)


    workbook = RubyXL::Parser.parse(downloaded_file_path)
    sheet = workbook.worksheets[1].extract_data
    cdc_col = 2
    addr_col = 0
    client = Savon.client ENV['SHERIFF_WSDL']
    sheet.each do |row|

      if row[cdc_col]
        cdc_number = row[cdc_col]
        address_long = row[addr_col]
        puts "writs file row => " << row.to_s
        if cdc_number && cdc_number != "CDC ID"
          response = client.request 'm:GetForeclosure' do 
            http.headers['SOAPAction'] = ENV['SHERIFF_ACTION']
            soap.namespaces['xmlns:m'] = ENV['SHERIFF_NS']
            soap.body = {'m:cdcCaseNumber' => cdc_number, 'm:key' => ENV['SHERIFF_PASSWORD'] }
          end
          puts "Requesting cdcCaseNumber => #{cdc_number}"
          foreclosure = response.hash[:envelope][:body][:get_foreclosure_response][:get_foreclosure_result][:foreclosure]

          if foreclosure
            sale_dt = nil
            unless foreclosure[:sale_date] == "Null"
              sale_dt = DateTime.strptime(foreclosure[:sale_date], '%m/%d/%Y %H:%M:%S %p')
            end

            addr = {address_long: nil, house_num: nil, street_type: nil, street_name: nil}
            
            if foreclosure[:property_address]
              addr[:address_long] = foreclosure[:property_address]
              if addr[:address_long].end_with?(".")
                addr[:address_long] = addr[:address_long].chop
              end
              addr[:house_num] = addr[:address_long].split(' ')[0]
              addr[:street_type] = AddressHelpers.get_street_type addr[:address_long] 
              addr[:street_name] = AddressHelpers.get_street_name addr[:address_long]
            end
            
            Foreclosure.create(address_long: address_long, status: foreclosure[:sale_status], notes: "", sale_date: sale_dt, title: foreclosure[:case_title][0..254], cdc_case_number: foreclosure[:cdc_case_number], defendant: foreclosure[:defendant][0..254], plaintiff: foreclosure[:plaintiff][0..254], address_long: foreclosure[:property_address], street_name: addr[:street_name], street_type: addr[:street_type], house_num: addr[:house_num])
          end
        end
      end
    end
    puts "foreclosures:load_sheriff"
  end

  desc "Downloading CDC case numbers from s3.amazon.com"  
  task :load_cdcNumbers, [:cdc_numbers] => :environment  do |t, args|
    
    p args

    client = Savon.client ENV['SHERIFF_WSDL']
    args[:cdc_numbers].split('|').each do |cdc_number|# sheet.each do |row|

      
          response = client.request 'm:GetForeclosure' do 
            http.headers['SOAPAction'] = ENV['SHERIFF_ACTION']
            soap.namespaces['xmlns:m'] = ENV['SHERIFF_NS']
            soap.body = {'m:cdcCaseNumber' => cdc_number, 'm:key' => ENV['SHERIFF_PASSWORD'] }
          end
          puts "Requesting cdcCaseNumber => #{cdc_number}"
          foreclosure = response.hash[:envelope][:body][:get_foreclosure_response][:get_foreclosure_result][:foreclosure]

          if foreclosure
            puts foreclosure
            sale_dt = nil
            unless foreclosure[:sale_date] == "Null"
              sale_dt = DateTime.strptime(foreclosure[:sale_date], '%m/%d/%Y %H:%M:%S %p')
            end

            addr = {address_long: nil, house_num: nil, street_type: nil, street_name: nil}
            
            if foreclosure[:property_address]
              addr[:address_long] = foreclosure[:property_address]
              if addr[:address_long].end_with?(".")
                addr[:address_long] = addr[:address_long].chop
              end
              addr[:house_num] = addr[:address_long].split(' ')[0]
              addr[:street_type] = AddressHelpers.get_street_type addr[:address_long] 
              addr[:street_name] = AddressHelpers.get_street_name addr[:address_long]
            end
            
            Foreclosure.create(address_long: address_long, status: foreclosure[:sale_status], notes: "", sale_date: sale_dt, title: foreclosure[:case_title][0..254], cdc_case_number: foreclosure[:cdc_case_number], defendant: foreclosure[:defendant][0..254], plaintiff: foreclosure[:plaintiff][0..254], address_long: foreclosure[:property_address], street_name: addr[:street_name], street_type: addr[:street_type], house_num: addr[:house_num])
          end
    end
    puts "foreclosures:load_cdcNumbers"
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

  desc "Correlate foreclosure data with cases"  
  task :match_case => :environment  do |t, args|
    # go through each demolition
    foreclosures = Foreclosure.where("address_id is not null and case_number is null")
    AbatementHelpers.match_case(foreclosures)
  end

  desc "Delete all foreclosures from database"
  task :drop => :environment  do |t, args|
    Foreclosure.destroy_all
  end
end
