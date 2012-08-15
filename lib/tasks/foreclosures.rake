require "#{Rails.root}/lib/import_helpers.rb"
require "#{Rails.root}/lib/spreadsheet_helpers.rb"
require "#{Rails.root}/lib/address_helpers.rb"

include ImportHelpers
include SpreadsheetHelpers
include AddressHelpers
require 'savon'

namespace :foreclosures do
  desc "Downloading files from s3.amazon.com"  
  task :load, [:file_name, :bucket_name] => :environment  do |t, args|
    # args.with_defaults(:bucket_name => "neworleansdata", :file_name => "Sheriff Sale.xlsx")  
    # puts args

    #connect to amazon
    # ImportHelpers.connect_to_aws
    # s3obj = AWS::S3::S3Object.find args.file_name, args.bucket_name
    # downloaded_file_path = ImportHelpers.download_from_aws(s3obj)

    # oo = Excelx.new(downloaded_file_path)
    # oo.default_sheet = oo.sheets[7]

    # 38.upto(oo.last_row) do |row|  
    #   unless oo.row(row)[8].to_s.empty?
    #     Foreclosure.create(:house_num => oo.row(row)[8], :street_name => AddressHelpers.get_street_name(oo.row(row)[9]), :address_long => "#{oo.row(row)[8].to_i} #{oo.row(row)[9]}".upcase, :notes => oo.row(row)[13], :sale_date => oo.row(row)[14])
    #   end        
    # end 
    client = Savon.client("http://www.civilsheriff.com/ForeclosureWebService/Foreclosure.svc?wsdl")
    response = client.request :get_all_users
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
