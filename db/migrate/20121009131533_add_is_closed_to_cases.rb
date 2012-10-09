class AddIsClosedToCases < ActiveRecord::Migration
  def up
  	add_column :cases, :outcome, :string
  end

  def down
  	remove_column :cases, :outcome
  end
end
