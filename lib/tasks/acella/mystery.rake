require "#{Rails.root}/lib/import_helpers.rb"
require 'iconv'

include ImportHelpers

namespace :mystery do
  desc "Download and load mystery report from s3.amazon.com"
  task :load, [:file_name, :bucket_name] => :environment do |t, args|
    #workflow_map = { 16 => "Case Manager", 17 => "Supervisor Review", 18 => "Schedule Hearing", 19 => "Times Posting", 20 => "Web Posted", 21=>"Hearing", 22=>"Inspection (Posting of Judgement)", 23=>"Short Term Remediation", 24=>"Demolition", 25=>"Administrative", 26=>"Lien Foreclosure", 27=>"Inspection", 28=>"Closed", 29=>"Record Judgement", 30=>"Supervisor Review- Judgement" }, "HCEVU" => { }, "HCEC" => {}, "HCEID" => {}, "HCES" => { 1 => "Verify Owner", 2=> "Closed", 3=>"Sweep inspection"} }

    args.with_defaults(:bucket_name => "neworleansdata", :file_name => "HCEB Mystery Report.xls")
    puts args

    ImportHelpers.connect_to_aws
    s3obj = AWS::S3::S3Object.find args.file_name, args.bucket_name
    downloaded_file_path = ImportHelpers.download_from_aws(s3obj)

    oo = Excel.new(downloaded_file_path)
    oo.default_sheet = oo.sheets.first
    l = oo.last_row
    [2..l].each do |index|
      row = oo.row(index)
      c = Case.find_or_initialize_by_case_number(:case_number => row[0], :geopin => row[3])

      address = AddressHelpers.find_address(row[1])
      unless address.empty?
        c.address = address.first
      end

      if [5, 6, 27].include?(row[5].to_i) #inspection
        i = Inspection.new(:inspection_type => row[6], :inspection_date => row[8], :result => row[7])
        i.case = c
        i.save
      end

      if row[5].to_i == 21 #hearing
        h = Hearing.new(:hearing_date => row[8])
        h.case = c
        h.save
      end

      if [10, 19, 20].include?(row[5].to_i) #notification
        n = Notification.new(:notified => row[8], :notification_type => row[6])
        n.case = c
        n.save
      end

      c.save
    end
  end
end
