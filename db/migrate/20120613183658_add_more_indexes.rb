class AddMoreIndexes < ActiveRecord::Migration
  def up
    add_index :inspections, :case_number
    add_index :hearings, :case_number
    add_index :judgements, :case_number
    add_index :resets, :case_number
  end

  def down
    remove_index :inspections, :case_number
    remove_index :hearings, :case_number
    remove_index :judgements, :case_number
    remove_index :resets, :case_number
  end
end
