class ChangeLastStepInCases < ActiveRecord::Migration
  def up
  	rename_column :cases, :last_step, :state
  end

  def down
  	rename_column :cases, :state, :last_step
  end
end
