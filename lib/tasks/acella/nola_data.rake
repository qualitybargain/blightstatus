namespace :acella do
  namespace :nola_data do
    desc "Load all Accela and spreadsheet data"
    task :load_blight_lists do
      Rake::Task["acella:inspections:load"].invoke
      Rake::Task["acella:hearings:load"].invoke
      # Rake::Task["acella:resets:load_multiples"].invoke
      Rake::Task["demolitions:load_socrata"].invoke
      Rake::Task["demolitions:load_fema"].invoke
      Rake::Task["demolitions:load_nora"].invoke
      Rake::Task["demolitions:load_nosd"].invoke
      Rake::Task["demolitions:match"].invoke
      Rake::Task["foreclosures:load_sheriff"].invoke
      Rake::Task["foreclosures:match"].invoke
      Rake::Task["maintenances:load"].invoke
      Rake::Task["maintenances:match"].invoke
    end

    desc "Load data for May 9th demo"
    task :load_demo_data do
      #inspections
      Rake::Task["inspections:load"].invoke("HCEB_Completed_Inspection_by_Inspector_050111-063011.xls")
      Rake::Task["inspections:load"].reenable
      Rake::Task["inspections:load"].invoke("HCEB_Completed_Inspection_by_Inspector_020112-033112.xls")
      Rake::Task["inspections:load"].reenable
      Rake::Task["inspections:load"].invoke("HCEB_Completed_Inspection_by_Inspector_20110701-20110831.xls")
      Rake::Task["inspections:load"].reenable
      Rake::Task["inspections:load"].invoke("HCEB_Completed_Inspection_by_Inspector_20111101-20120131.xls")
      Rake::Task["inspections:load"].reenable
      Rake::Task["inspections:load"].invoke("HCEB_Completed_Inspection_by_Inspector_20120401-20120501.xls")
      Rake::Task["inspections:load"].reenable
      Rake::Task["inspections:load"].invoke("HCEB_Completed_Inspections_By_Inspector_20110901-20110930.xls")
      Rake::Task["inspections:load"].reenable
      Rake::Task["inspections:load"].invoke("HCEB_Completed_Inspections_By_Inspector_20111001-20111031.xls")

      #hearings
      Rake::Task["hearings:load"].invoke("HCEB_Hearings_Docket_09012011-10312011.xls")
      Rake::Task["hearings:load"].reenable
      Rake::Task["hearings:load"].invoke("HCEB_Hearings_Docket_02012012-03312012.xls")
      Rake::Task["hearings:load"].reenable
      Rake::Task["hearings:load"].invoke("HCEB_Hearings_Docket_04012012-05012012.xls")
      Rake::Task["hearings:load"].reenable
      Rake::Task["hearings:load"].invoke("HCEB_Hearings_Docket_20120701-20110831.xls")
      Rake::Task["hearings:load"].reenable
      Rake::Task["hearings:load"].invoke("HCEB_Hearings_Docket_20110501-20110630.xls")
      Rake::Task["hearings:load"].reenable
      Rake::Task["hearings:load"].invoke("HCEB_Hearings_Docket_11012011-01312012.xls")

      #resets
      Rake::Task["resets:load_multiples"].invoke("HCEB_Multiple_Resets_20120301-20120501.pdf")
      Rake::Task["resets:load_multiples"].reenable
      Rake::Task["resets:load_multiples"].invoke("HCEB_Multiple_Resets_20120101-20120301.pdf")
      Rake::Task["resets:load_multiples"].reenable
      Rake::Task["resets:load_multiples"].invoke("HCEB_Multiple_Resets_20111101-20120101.pdf")
      Rake::Task["resets:load_multiples"].reenable
      Rake::Task["resets:load_multiples"].invoke("HCEB_Multiple_Resets_20110901-20111101.pdf")
      Rake::Task["resets:load_multiples"].reenable
      Rake::Task["resets:load_multiples"].invoke("HCEB_Multiple_Resets_20110701-20110901.pdf")
      Rake::Task["resets:load_multiples"].reenable
      Rake::Task["resets:load_multiples"].invoke("HCEB_Multiple_Resets_20110501-20110701.pdf")

      #mysteries
      Rake::Task["mystery:load"].invoke("HCEB_Mystery_Backlog_20120301-20120501.xls")
      Rake::Task["mystery:load"].reenable
      Rake::Task["mystery:load"].invoke("HCEB_Mystery_Backlog_20120101-20120301.xls")
      Rake::Task["mystery:load"].reenable
      Rake::Task["mystery:load"].invoke("HCEB_Mystery_Backlog_20111101-20120101.xls")
      Rake::Task["mystery:load"].reenable
      Rake::Task["mystery:load"].invoke("HCEB_Mystery_Backlog_20110901-20111101.xls")
      Rake::Task["mystery:load"].reenable
      Rake::Task["mystery:load"].invoke("HCEB_Mystery_Backlog_20110701-20110901.xls")
      Rake::Task["mystery:load"].reenable
      Rake::Task["mystery:load"].invoke("HCEB_Mystery_Backlog_20110501-20110701.xls")

      #Demos
      Rake::Task["demolitions:load_socrata"].invoke
      Rake::Task["demolitions:match"].invoke

      #INAP
      Rake::Task["maintenances:load_2011"].invoke
      Rake::Task["maintenances:load"].invoke("INAP_Jan2012.xlsm")
      Rake::Task["maintenances:load"].reenable
      Rake::Task["maintenances:load"].invoke("INAP_Feb2012.xlsm")
      Rake::Task["maintenances:load"].reenable
      Rake::Task["maintenances:load"].invoke("INAP_March2012.xlsm")
      Rake::Task["maintenances:match"].invoke

      #Forclosures
      Rake::Task["foreclosures:load"].invoke
      Rake::Task["foreclosures:match"].invoke
    end

    desc "Load all data including parcels and addresses" 
    task :load_all do
      Rake::Task["addresses:load"].invoke
      Rake::Task["streets:load"].invoke
      Rake::Task["parcels:load"].invoke

      Rake::Task["nola_data:load_blight_lists"]
    end

    desc "Delete all workflow data from database"
    task :drop do
      Rake::Task["inspections:drop"].invoke
      Rake::Task["hearings:drop"].invoke
      Rake::Task["demolitions:drop"].invoke
      Rake::Task["foreclosures:drop"].invoke
      Rake::Task["maintenances:drop"].invoke
    end
  end
end
