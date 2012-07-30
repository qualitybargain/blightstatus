class ChangeStatusToStringMaintenances < ActiveRecord::Migration
  def up
  	change_table :maintenances do |t|
      t.change :status, :string
  	end
  end

  def down
  	change_table :maintenances do |t|
      t.change :status, :datetime
    end
  end
end