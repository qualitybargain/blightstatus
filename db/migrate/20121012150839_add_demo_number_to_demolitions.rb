class AddDemoNumberToDemolitions < ActiveRecord::Migration
  def change
  	add_column :demolitions, :demo_number, :string
  end
end
