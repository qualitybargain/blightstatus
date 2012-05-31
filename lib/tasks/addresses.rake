require 'rgeo/shapefile'
require "#{Rails.root}/lib/address_helpers.rb"

namespace :addresses do
  desc "Load data.nola.gov addresses into database"
  task :load => :environment do

    Address.where(:official => true).destroy_all
    shpfile = "#{Rails.root}/lib/assets/NOLA_Addresses_20120309_wgs84/NOLA_Addresses_20120309_wgs84.shp"
    dist_shpfile = "#{Rails.root}/lib/assets/NOLA_Council_Districts_wgs84/NOLA_Council_Districts_wgs84.shp"
    districts = {}

    RGeo::Shapefile::Reader.open(dist_shpfile) do |file|
      file.each do |record|
        districts[record.attributes["OBJECTID"]] = {:council_district => record.attributes["COUNCILDIS"], :geom => record.geometry}
      end
    end

    RGeo::Shapefile::Reader.open(shpfile, {:srid => -1}) do |file|
      puts "File contains #{file.num_records} records"
      file.each do |n|
         record = n.attributes
         a = Address.create(:point => n.geometry, :official => true, :address_id => record["ADDRESS_ID"], :street_full_name => record["ADDRESS_LA"].sub(/^\d+\s/, ''), :address_long => record["ADDRESS_LA"], :geopin => record["GEOPIN"], :house_num => record["HOUSE_NUMB"], :parcel_id => record["PARCEL_ID"], :status => record["STATUS"], :street_id => record["STREET_ID"], :street_name => record["STREET"], :street_type => record["TYPE"], :x => record["X"], :y => record["Y"] )
         districts.each do |d|
           if d[1][:geom].contains?(a.point)
             a.case_district = d[1][:council_district]
           end
         end
         a.save
      end
    end
  end

  desc "Empty address table"  
  task :drop => :environment  do |t, args|
    Address.destroy_all
  end

  desc "Set assessor_url for all addresses"
  task :set_assessor_url => :environment do |t, args|
    Address.all.each{ |a| a.set_assessor_link }
  end

  desc "call get neighborhood"
  task :get_neighborhood => :environment do
    #addresses = Address.all
    a = Address.find(1)#addresses.each do |a|
      #example: http://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&sensor=true
      #http://maps.googleapis.com/maps/api/geocode/xml?address=298+Fairmount+Ave,+Oakland,+CA&sensor=true
      puts "lat: #{a.y} and long: #{a.x}"
      AddressHelpers.get_neighborhood(a.y,a.x)

    #end
  end
end
