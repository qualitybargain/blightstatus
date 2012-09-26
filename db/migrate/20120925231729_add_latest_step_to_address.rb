class AddLatestStepToAddress < ActiveRecord::Migration
  def change
    add_column :addresses, :latest_type, :string
    add_column :addresses, :latest_id, :integer
  end
end
