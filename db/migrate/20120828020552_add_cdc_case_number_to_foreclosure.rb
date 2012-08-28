class AddCdcCaseNumberToForeclosure < ActiveRecord::Migration
  def change
  	add_column :foreclosures, :cdc_case_number, :string
  	add_column :foreclosures, :title, :string
  	add_column :foreclosures, :defendent, :string
  	add_column :foreclosures, :plaintiff, :string
  end
end
