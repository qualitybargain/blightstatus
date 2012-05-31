class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :address_id, :uniqueness => true
      t.integer :account_id
	    t.string :notes
      t.geometry :thegeom

      t.timestamps
    end
    add_foreign_key(:subscriptions, :addresses)
    add_foreign_key(:subscriptions, :accounts)
  end
end
