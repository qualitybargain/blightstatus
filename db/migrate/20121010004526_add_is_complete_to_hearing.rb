class AddIsCompleteToHearing < ActiveRecord::Migration
  def change
    add_column :hearings, :is_complete, :boolean
  end
end
