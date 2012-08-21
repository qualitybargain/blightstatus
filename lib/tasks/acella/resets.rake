require "#{Rails.root}/lib/import_helpers.rb"
require 'docsplit'
include ImportHelpers

namespace :resets do
  desc "Load Multiple Resets report into database"
  task :load_multiples, [:file_name, :bucket_name] => :environment do |t, args|
    args.with_defaults(:bucket_name => "neworleansdata", :file_name => "HCEB Multiple Resets.pdf")
    p args

    ImportHelpers.connect_to_aws
    s3obj = AWS::S3::S3Object.find(args.file_name, args.bucket_name)
    downloaded_file_path = ImportHelpers.download_from_aws(s3obj)
    
    Docsplit.extract_text(downloaded_file_path, :ocr => false, :output => "#{Rails.root}/tmp/text")

    file = File.open("#{Rails.root}/tmp/text/#{args.file_name.gsub('pdf', 'txt')}", "r")
    case_num = ""
    file.each_with_index do |line, i|
      case
      when /CEHB|HCEB/ =~ line
        case_num = line.strip
      when /^\d{8}$/ =~ line
        c = Case.find_or_create_by_case_number(:case_number => case_num, :geopin => line)
      when /^(\d{2}\/){2}\d{4}/ =~ line
        m = /^(\d{2})\/(\d{2})\/(\d{4})/.match(line)
        Reset.create(:case_number => case_num, :reset_date => Date.new(m[3].to_i, m[1].to_i, m[2].to_i))
      end
    end

  end
end
