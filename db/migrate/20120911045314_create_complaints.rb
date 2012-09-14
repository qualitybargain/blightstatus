class CreateComplaints < ActiveRecord::Migration
  def change
    create_table :complaints do |t|
      
      t.string :status
      t.datetime :date_received
      t.string :case_number
	  t.string :notes
      
      t.timestamps
    end

  end
end