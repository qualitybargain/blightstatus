require "#{Rails.root}/lib/import_helpers.rb"
require "#{Rails.root}/lib/spreadsheet_helpers.rb"
require "#{Rails.root}/lib/address_helpers.rb"
require "#{Rails.root}/lib/abatement_helpers.rb"

include ImportHelpers
include SpreadsheetHelpers
include AddressHelpers
include AbatementHelpers


namespace :demolitions do
  desc "Downloading FEMA files from s3.amazon.com and load them into the db"  
  task :load_fema, [:file_name, :bucket_name] => :environment  do |t, args|
    args.with_defaults(:bucket_name => "neworleansdata", :file_name => "FEMA Validated_Demo_DataEntry_2012_January.xlsx")  
    p args

    ImportHelpers.connect_to_aws
    s3obj = AWS::S3::S3Object.find args.file_name, args.bucket_name
    downloaded_file_path = ImportHelpers.download_from_aws(s3obj)

    SpreadsheetHelpers.workbook_to_hash(downloaded_file_path).each do |row|
      unless SpreadsheetHelpers.row_is_empty? row
        if row['Status Update']  == '12.Demolished'
          if row['Number'].to_s.end_with?(".0")
            row['Number'] = row['Number'].to_i.to_s
          end
          Demolition.find_or_create_by_address_long_and_date_completed(:house_num => row['Number'], :street_name => row['Street'].upcase, :address_long => "#{row['Number']} #{row['Street']}".upcase, :date_started => row['Demo Start'], :date_completed => row['Demo Complete'], :program_name => "NORA")
        end
      end
    end
  end

  desc "Downloading NORA files from s3.amazon.com and load them into the db"  
  task :load_nora, [:file_name, :bucket_name] => :environment  do |t, args|
    args.with_defaults(:bucket_name => "neworleansdata", :file_name => "NORA Validated_Demo_DataEntry_2012.xlsx")  
    p args

    ImportHelpers.connect_to_aws
    s3obj = AWS::S3::S3Object.find args.file_name, args.bucket_name
    downloaded_file_path = ImportHelpers.download_from_aws(s3obj)

    SpreadsheetHelpers.workbook_to_hash(downloaded_file_path).each do |row|
      unless SpreadsheetHelpers.row_is_empty? row
        if row['Number'].to_s.end_with?(".0")
            row['Number'] = row['Number'].to_i.to_s
          end
        Demolition.create(:house_num => row['Number'], :street_name => row['Street'].upcase, :address_long =>  row['Address'].upcase, :date_started => row['Demo Start'], :date_completed => row['Demo Complete'], :program_name => "NORA")
      end
    end
  end

  desc "Downloading NOSD files from s3.amazon.com and load them into the db"  
  task :load_nosd, [:file_name, :bucket_name] => :environment  do |t, args|
    args.with_defaults(:bucket_name => "neworleansdata", :file_name => "NOSD  BlightStat Report  January 2012.xlsx")  
    p args

    ImportHelpers.connect_to_aws
    s3obj = AWS::S3::S3Object.find args.file_name, args.bucket_name
    downloaded_file_path = ImportHelpers.download_from_aws(s3obj)

    SpreadsheetHelpers.workbook_to_hash(downloaded_file_path).each do |row|
      unless SpreadsheetHelpers.row_is_empty? row
        if row['Number'].to_s.end_with?(".0")
          row['Number'] = row['Number'].to_i.to_s
        end
        #:date_completed => row['Demo Complete'], this throws error. need to format date.
        Demolition.create(:house_num => row['Number'], :street_name => row['Street'].upcase, :address_long =>  row['Address'].upcase, :date_started => row['Demo Start'],  :program_name => "NOSD")
      end
    end
  end



  desc "Downloading LAMA Permit Demolition files from s3.amazon.com and load them into the db"  
  task :load_lama_demolition_permits, [:file_name, :bucket_name] => :environment  do |t, args|
    args.with_defaults(:bucket_name => "neworleansdata", :file_name => "tung_demolitions_oct_2012.xls")

    ImportHelpers.connect_to_aws
    s3obj = AWS::S3::S3Object.find args.file_name, args.bucket_name
    downloaded_file_path = ImportHelpers.download_from_aws(s3obj)

    SpreadsheetHelpers.workbook_to_hash(downloaded_file_path).each do |row|
       unless SpreadsheetHelpers.row_is_empty? row
         if row["Current Status"] =~ /Certificate of Completion/
           Demolition.create(:address_long => row['Address'].upcase, :date_completed => row['Current Status Date'])
         else
         end
        #Demolition.create(:house_num => row['Number'], :street_name => row['Street'].upcase, :address_long =>  row['Address'].upcase, :date_started => row['Demo Start'],  :program_name => "NOSD")
        # YES
        # Current Status
        # "Certificate of Occupancy - Issued No Meter"
      end
    end
  end

  desc "Downloading Socrata files from s3.amazon.com and load them into the db"
  task :load_socrata => :environment  do |t, args|
    properties = ImportHelpers.download_json_convert_to_hash('https://data.nola.gov/api/views/abvi-rghr/rows.json?accessType=DOWNLOAD')
    exceptions = []
    properties[:data].each do |row|
      begin
        house_num = row[11].split(' ')[0]
        Demolition.find_or_create_by_address_long_and_date_completed(:house_num => house_num, :street_name => row[11].sub(house_num + ' ', '').upcase, :address_long =>  row[11], :date_completed => row[14], :program_name => row[8])
      rescue
        #these exceptions are for properties that are missing most data, except for address, date demolished, and program (they are all NORA). What do we want to do with them?
        exceptions.push({ :exception => $!, :row => row })
      end
    end
    
    if exceptions.length
      puts "There are #{exceptions.length} import errors"
      exceptions.each do |e|
        puts " OBJECT ID: #{e[:row][2]}, ERROR: #{e[:exception]}"
      end
    end
  end

  desc "Correlate demolition data with addresses"  
  task :match => :environment  do |t, args|
    # go through each demolition
    success = 0
    failure = 0
    case_matches = 0;

    Demolition.all.each do |row|
      # compare each address in demo list to our address table
      #address = Address.where("address_long LIKE ?", "%#{row.address_long}%")
      address = AddressHelpers.find_address(row.address_long)

      unless (address.empty?)
        demo = Demolition.find(row.id)
        demo.update_attributes(:address_id => address.first.id)
        success += 1

        demo.address.cases.each do |c|
          unless Judgement.where("case_number = :case_number", {:case_number => c.case_number}).nil?
            demo.update_attributes(:case_number => c.case_number)
            case_matches += 1;
          end
        end
        
      else
        puts "#{row.address_long} address not found in address table "
        failure += 1
      end
    end


    puts "There were #{success} successful address matches and #{failure} failed address matches and #{case_matches} cases matched"      
  end

  desc "Correlate demolition data with cases"  
  task :match_case => :environment  do |t, args|
    # go through each demolition
    demos = Demolition.where("address_id is not null and case_number is null")
    AbatementHelpers.match_case(demos)
  end

  desc "Delete all demolitions from database"
  task :drop => :environment  do |t, args|
    Demolition.destroy_all
  end
end
