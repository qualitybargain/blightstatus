require "#{Rails.root}/lib/import_helpers.rb"
require 'iconv'

include ImportHelpers

# this class should be generalized
# take in arguments from command line for: Bucket Name, File Name
# maybe also take in a hash of what excel columns should be paired up with in model
# the script should also detect different file formats and use the proper parser

# this script works locally, needs testing in different systems
namespace :acella do
  namespace :hearings do
    desc "Downloading files from s3.amazon.com"  
    task :load, [:file_name, :bucket_name] => :environment  do |t, args|
          args.with_defaults(:bucket_name => "neworleansdata", :file_name => "HCEB Hearing Docket for Hearing Dates.xls")  
          puts args

          #connect to amazon
          ImportHelpers.connect_to_aws
          s3obj = AWS::S3::S3Object.find args.file_name, args.bucket_name
          downloaded_file_path = ImportHelpers.download_from_aws(s3obj)

          oo = Excel.new(downloaded_file_path)
          oo.default_sheet = oo.sheets.first
          21.upto(oo.last_row) do |row|

              if oo.row(row)[0].nil?
                  next
              end

              address = AddressHelpers.find_address(oo.row(row)[0])
              if address.empty?
                address = AddressHelpers.find_address_by_geopin(oo.row(row)[35])
                c = Case.find_or_create_by_case_number(:case_number => oo.row(row)[10], :geopin => oo.row(row)[35])
              else
                add_id = address.first.id
                c = Case.find_or_create_by_case_number(:case_number => oo.row(row)[10], :geopin => oo.row(row)[35], :address_id => add_id)
              end

              m = CaseManager.find_or_create_by_name(:name => oo.row(row)[11],:case_number => oo.row(row)[10])
              status = oo.row(row)[21]
              unless status.nil?
                  status = status.split(" ")[0].delete(":").downcase
              end

              hearing_datetime = nil

              unless oo.row(row)[19].nil?
                  date = oo.row(row)[19].to_s.split("-")
                  time = 0
                  unless oo.row(row)[20].nil? 
                      time = oo.row(row)[20]
                  end
                  time = Time.at(time).gmtime.strftime('%R:%S')
                  time = time.split(":")
                  hearing_datetime = DateTime.new(date[0].to_i,date[1].to_i,date[2].to_i,time[0].to_i,time[1].to_i,time[2].to_i)
              end

              if status && status != "reset"
                  Judgement.find_or_create_by_case_number_and_status(:case_number => oo.row(row)[10], :status => status, :notes => oo.row(row)[21], :judgement_date => hearing_datetime)
              end

              unless oo.row(row)[22].nil?
                  date = oo.row(row)[22].to_s.split("/")
                  time = 0
                  unless oo.row(row)[23].nil?
                      time = oo.row(row)[23]
                  end
                  time = Time.at(time).gmtime.strftime('%R:%S')
                  time = time.split(":")

                  reset_date = DateTime.new(date[2].to_i,date[0].to_i,date[1].to_i,time[0].to_i,time[1].to_i,time[2].to_i)
                  Reset.create(:case_number => oo.row(row)[10], :reset_date => reset_date, :notes => oo.row(row)[21])
              end

              unless oo.row(row)[14].nil?
                  Notification.create(:case_number => oo.row(row)[10], :notified => oo.row(row)[14], :notification_type => 'Notice of Hearing')
              end

              Hearing.create(:case_number => c.case_number, :hearing_date => hearing_datetime, :hearing_status => status, :reset_hearing => oo.row(row)[22].nil?, :one_time_fine => oo.row(row)[25], :court_cost => oo.row(row)[25], :recordation_cost => oo.row(row)[26], :hearing_fines_owed => oo.row(row)[27], :daily_fines_owed => oo.row(row)[28], :fines_paid => oo.row(row)[29], :date_paid => oo.row(row)[30], :amount_still_owed => oo.row(row)[31], :grace_days=> oo.row(row)[32], :grace_end => oo.row(row)[33], :case_manager => m.id, :tax_id => oo.row(row)[34])
              status = nil
          end
      end

    desc "Delete all cases, case managers, judgements, notifications, and resets from database"
    task :drop => :environment  do |t, args|
          Case.destroy_all
          CaseManager.destroy_all
          Judgement.destroy_all
          Notification.destroy_all
          Reset.destroy_all
    end
  end
end
