class AddAbatementConfidence < ActiveRecord::Migration
  def up
  		add_column :foreclosures, :case_confidence, :boolean
  		add_column :demolitions, :case_confidence, :boolean
  		add_column :maintenances, :case_confidence, :boolean
  end

  def down
  		remove_column :foreclosures, :case_confidence
  		remove_column :demolitions, :case_confidence
  		remove_column :maintenances, :case_confidence
  end
end
