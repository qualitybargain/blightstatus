require "#{Rails.root}/lib/import_helpers.rb"
require "#{Rails.root}/lib/spreadsheet_helpers.rb"
require "#{Rails.root}/lib/address_helpers.rb"
require "savon"

include ImportHelpers
include SpreadsheetHelpers
include AddressHelpers
include Savon

namespace :foreclosures do
  desc "Downloading files from s3.amazon.com"  
  task :load, [:file_name, :bucket_name] => :environment  do |t, args|
    
    client = Savon.client ENV['SHERIFF_WSDL']
    response = client.request 'm:GetForeclosure' do  #:get_foreclosure do
      http.headers['SOAPAction'] = %("http://www.civilsheriff.com/ForeclosureWebService/IForeclosure/GetForeclosure")
      soap.namespaces['xmlns:m'] = 'http://www.civilsheriff.com/ForeclosureWebService'
      soap.body = {'m:cdcCaseNumber' => "2012-5607", 'm:key' => ENV['SHERIFF_PASSWORD'] }
    end
    puts response.body
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
