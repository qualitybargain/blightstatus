class AddIsValidToSteps < ActiveRecord::Migration
  def up
  	add_column :complaints, :is_valid, :boolean
  	add_column :inspections, :is_valid, :boolean
  	add_column :notifications, :is_valid, :boolean
  	add_column :hearings, :is_valid, :boolean
  	add_column :judgements, :is_valid, :boolean
  	add_column :resets, :is_valid, :boolean
  end

  def down
  	remove_column :complaints, :is_valid
  	remove_column :inspections, :is_valid
  	remove_column :notifications, :is_valid
  	remove_column :hearings, :is_valid
  	remove_column :judgements, :is_valid
  	remove_column :resets, :is_valid
  end
end
