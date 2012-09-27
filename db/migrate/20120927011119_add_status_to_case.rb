class AddStatusToCase < ActiveRecord::Migration
  def up
  	add_column :cases, :status, :string
  end

  def down
  	remove_column :cases, :status
  end
end
