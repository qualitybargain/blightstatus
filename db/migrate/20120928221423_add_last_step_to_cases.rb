class AddLastStepToCases < ActiveRecord::Migration
  	def up
  		add_column :cases, :last_step, :string
  	end
  
  def down
  		remove_column :cases, :last_step, :string
  end
end
