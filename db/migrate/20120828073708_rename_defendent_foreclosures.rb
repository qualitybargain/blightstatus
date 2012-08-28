class RenameDefendentForeclosures < ActiveRecord::Migration
  def up
  	rename_column :foreclosures, :defendent, :defendant
  end

  def down
  	rename_column :foreclosures, :defendant, :defendent
  end
end
