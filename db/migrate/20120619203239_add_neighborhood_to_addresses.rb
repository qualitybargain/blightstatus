class AddNeighborhoodToAddresses < ActiveRecord::Migration
  def change
  	add_column :addresses, :neighborhood_id, :integer
  
  end
end
