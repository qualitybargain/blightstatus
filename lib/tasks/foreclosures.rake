require "#{Rails.root}/lib/import_helpers.rb"
require "#{Rails.root}/lib/spreadsheet_helpers.rb"
require "#{Rails.root}/lib/address_helpers.rb"

include ImportHelpers
include SpreadsheetHelpers
include AddressHelpers
include Savon

namespace :foreclosures do
  desc "Downloading files from s3.amazon.com"  
  task :load, [:file_name, :bucket_name] => :environment  do |t, args|
    
    
    client = Savon::Client.new(ENV['SHERIFF_WSDL'])
    puts "ENV['SHERIFF_WSDL'] => " + ENV['SHERIFF_WSDL']
    puts "ENV['SHERIFF_USER'] => " + ENV['SHERIFF_USER']
    puts "ENV['SHERIFF_PASSWORD'] => " + ENV['SHERIFF_PASSWORD']
    
    client.request.basic_auth ENV['SHERIFF_USER'], ENV['SHERIFF_PASSWORD']
    client.wsdl.soap_actions
    #response = client.http.request(:get_foreclosure)#{soap.body = { "CdcCaseNumber" => 1 }}
    

    #puts response.body
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
