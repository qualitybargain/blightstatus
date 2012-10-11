class AddSpawnToJudgments < ActiveRecord::Migration
  def change
  	add_column :complaints, :spawn_id, :integer
  	add_column :inspections, :spawn_id, :integer
  	add_column :notifications, :spawn_id, :integer
  	add_column :hearings, :spawn_id, :integer
  	add_column :judgements, :spawn_id, :integer
  	add_column :resets, :spawn_id, :integer
  end
end
