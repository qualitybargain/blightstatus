require "#{Rails.root}/lib/import_helpers.rb"
require "#{Rails.root}/lib/spreadsheet_helpers.rb"
include SpreadsheetHelpers
include ImportHelpers

namespace :acella do
  namespace :generic_importer do
    desc "This is an experimental importer for a list of spreedsheets"
    task :load => :environment  do |t, args|
      settings = YAML.load_file("#{Rails.root}/config/generic_importer.yml")
      
      #connect to amazon
      ImportHelpers.connect_to_aws
      
      settings['Models'].each_with_index() do |current, index|  
        
        puts "#{current['name']}"
        
        Object::const_get(current['name']).destroy_all
      
        s3obj = AWS::S3::S3Object.find current['filename'], current['bucketname']
        
        file_path = ImportHelpers.download_from_aws(s3obj)
    
        # we get convert the roo object into an addressable hash then...
        table_data = workbook_to_hash(file_path)
        
        # we then loop through each row ...
        table_data.each_with_index do |spreadsheet_row, index|        
          row_data = {}
          
          # matching spreadsheet column names with database column names 
          current['column_map'].each_with_index do |(db_column_name, spreadsheet_column_name),index|
              
              # check config file to see if any of these column/value combinations are going to be skipped
              unless current['filter_exclude'].nil?
                current['filter_exclude'].each_with_index do |(filter_column_name, filter_value),index|
                  if db_column_name == filter_column_name && spreadsheet_row[spreadsheet_column_name] == filter_value
                    puts "We are skipping #{db_column_name} / #{filter_value}" rescue nil
                    next                  
                  end
                end
              end
              

              # check config file to see if we are going to want to use only this column/value combinations
              unless current['filter_exclusive'].nil?
                current['filter_exclusive'].each_with_index do |(filter_column_name, filter_value),index|
                  if db_column_name == filter_column_name && spreadsheet_row[spreadsheet_column_name] == filter_value
                    puts "We are exclusively adding #{db_column_name} / #{filter_value}"
                    row_data[db_column_name] = spreadsheet_row[spreadsheet_column_name] rescue nil                  
                    next                  
                  end
                end
              end
              
            
              # if there are not filteres, we populate row_data with the column/value
              row_data[db_column_name] = spreadsheet_row[spreadsheet_column_name] rescue nil
          end

          # sometimes spreadsheets don't have a column/value pair that we want. we can pre-redefine column/values
          unless current['prepopulate'].nil?
            current['prepopulate'].each_with_index do |(db_column_name, preset_value),index|
                row_data[db_column_name] = preset_value
            end
          end

          # then insert into database!
          puts "#{row_data}"
          Object::const_get(current['name']).create(row_data)
        end
      end  
    end
  end
end
