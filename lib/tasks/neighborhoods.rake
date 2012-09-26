require 'rgeo/shapefile'
#require "#{Rails.root}/lib/address_helpers.rb"

namespace :neighborhoods do
  desc "Load data.nola.gov neighborhoods into database"
  task :load => :environment do

    Neighborhood.destroy_all
    shpfile = "#{Rails.root}/lib/assets/NOLA_Neighborhoods/Neighborhoods_wgs_84.shp"
    
    RGeo::Shapefile::Reader.open(shpfile, {:srid => -1}) do |file|
      puts "File contains #{file.num_records} records"
      file.each do |n|
         record = n.attributes
         Neighborhood.create(:name => record["SDC_LAB"], :x_min => record["XMIN"], :y_min => record["YMIN"], :x_max => record["XMAX"], :y_max => record["YMAX"], :area => record["SHAPE_area"], :the_geom => n.geometry)
      end
    end
  end

  desc "Empty neighborhood table"  
  task :drop => :environment  do |t, args|
    Neighborhood.destroy_all
  end
end
