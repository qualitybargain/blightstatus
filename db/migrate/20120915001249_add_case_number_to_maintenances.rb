class AddCaseNumberToMaintenances < ActiveRecord::Migration
  def up
  	add_column :maintenances, :case_number, :string
  end
  def down
  	remove_column :maintenances, :case_number
  end
end
