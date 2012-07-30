class CreateNeighborhoods < ActiveRecord::Migration
  def change
    create_table :neighborhoods do |t|
		t.string :name
		t.float :x_min
      	t.float :y_min
		t.float :x_max
      	t.float :y_max
      	t.float :area
      	t.geometry :the_geom
      t.timestamps
    end
  end
end
