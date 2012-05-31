class AddAssessorUrlToAddress < ActiveRecord::Migration
  def change
    add_column :addresses, :assessor_url, :string

  end
end
