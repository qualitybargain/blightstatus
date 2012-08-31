class CreateInspectionFindings < ActiveRecord::Migration
  def change
    create_table :inspection_findings do |t|
      t.integer :inspection_id
      t.text :finding
      t.string :label

      t.timestamps
    end
  end
end
