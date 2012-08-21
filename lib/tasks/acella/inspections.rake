require "#{Rails.root}/lib/import_helpers.rb"
require 'iconv'

include ImportHelpers

namespace :acella do
  namespace :inspections do
    desc "Downloading files from s3.amazon.com"  
    task :load, [:file_name, :bucket_name] => :environment  do |t, args|
      args.with_defaults(:bucket_name => "neworleansdata", :file_name => "HCEB Completed Insp by Inspector.xls")  
      puts args

      #connect to amazon
      ImportHelpers.connect_to_aws
      s3obj = AWS::S3::S3Object.find args.file_name, args.bucket_name
      downloaded_file_path = ImportHelpers.download_from_aws(s3obj)

      label = "Inspector:"  
      #these column names should be should not statically matched
      oo = Excel.new(downloaded_file_path)
      oo.default_sheet = oo.sheets.first
      inspector = nil
      exceptions = []
      1.upto(oo.last_row) do |row|
        begin
          unless (oo.row(row)[0].nil?)
            if oo.row(row)[0] == label then
              inspector = Inspector.find_or_create_by_name(oo.row(row)[3])
            end
            case_prefix = oo.row(row)[0].to_s
            if case_prefix.match(/\A(HCEB|CEHB|HCEC|HCES|HCEVU)/i)
              c = Case.find_or_initialize_by_case_number(:case_number => oo.row(row)[0], :geopin => oo.row(row)[23])
              address = AddressHelpers.find_address(oo.row(row)[5])
              unless address.empty?
                c.address = address.first
              else
                address = AddressHelpers.find_address_by_geopin(oo.row(row)[23])
                unless address.empty?
                  c.address = address.first
                end
              end
              c.save

              i = Inspection.create(:case_number => c.case_number, :result => oo.row(row)[11],:scheduled_date => oo.row(row)[16], :inspection_date => oo.row(row)[19], :inspection_type => oo.row(row)[21], :inspector_id => inspector.id) 
            end
          end
        rescue Exception=>e
          puts e.to_s
          puts oo.row(row).to_s
          exceptions.push("#{row} : #{e.to_s}")
        end  
      end

      if exceptions.length
        puts "There are #{exceptions.length} import errors errors"
        exceptions.each do |row|
          puts " Failed Record: #{row.to_s}"
        end
      end
    end

    desc "Delete all inspections and inspector data" 
    task :drop => :environment do |t|
      Inspection.destroy_all
      Inspector.destroy_all
    end
  end
end
