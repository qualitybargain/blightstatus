require 'rgeo/shapefile'

# TODO NEEDS TESTING

namespace :streets do
  desc "Load streets from data.nola.gov addresses into database"
  task :load => :environment do
    shpfile = "#{Rails.root}/lib/assets/NOLA_Streets_20120405/NOLA_Streets_20120405_wgs84.shp"

    RGeo::Shapefile::Reader.open(shpfile, {:srid => -1}) do |file|
      puts "File contains #{file.num_records} records"
      file.num_records.times do |n|
         record = file.get(n).attributes
         st = Street.create( :prefix_direction => record["PREFIX_DIR"], :prefix_type => record["PREFIX_TYP"], :name => record["ST_NAME"], :suffix_direction => record["SUFFIX_DIR"], :suffix_type => record["SUFFIX_TYP"], :full_name => record["NAME"], :shape_len => record["SHAPE_LEN"], :the_geom => file.get(n).geometry)
      end
    end
  end

  desc "Empty streets table"  
  task :drop => :environment  do |t, args|
    Street.destroy_all
  end
end


