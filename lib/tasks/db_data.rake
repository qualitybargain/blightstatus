namespace :db_data do
      desc "Load all abatement spreadsheet data"
      task :load_abatements do
            Rake::Task["demolitions:load_socrata"].invoke
            Rake::Task["demolitions:load_fema"].invoke
            Rake::Task["demolitions:load_nora"].invoke
            Rake::Task["demolitions:load_nosd"].invoke
            Rake::Task["demolitions:match"].invoke
            Rake::Task["maintenances:load"].invoke
            Rake::Task["maintenances:match"].invoke
            Rake::Task["foreclosures:load_writfile"].invoke
            Rake::Task["foreclosures:match"].invoke
      end

      desc "Load all abatement spreadsheet data"
      task :load_all do
            Rake::Task["addresses:load"].invoke
            Rake::Task["lama:load_historical"].invoke
            Rake::Task["db_data:load_abatements"].invoke
      end
end
