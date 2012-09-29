class AddStatusDateToCase < ActiveRecord::Migration
  def up
    add_column :cases, :status_id, :integer
    remove_column :cases, :status
    add_column :cases, :status_type, :string
  end

  def down
    remove_column :cases, :status_id
    remove_column :cases, :status_type
    add_column :cases, :status, :string
  end
end
