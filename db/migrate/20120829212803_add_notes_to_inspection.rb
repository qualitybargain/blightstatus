class AddNotesToInspection < ActiveRecord::Migration
  def change
    add_column :inspections, :notes, :text
    add_column :hearings, :hearing_type, :string
  end
end
