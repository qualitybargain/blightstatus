class AddDoubleIdToAddress < ActiveRecord::Migration
  def change
    add_column :addresses, :double_id, :integer

  end
end
