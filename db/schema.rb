# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121017012147) do

  create_table "accounts", :force => true do |t|
    t.string   "email",                  :default => "",   :null => false
    t.string   "encrypted_password",     :default => "",   :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.boolean  "send_notifications",     :default => true
  end

  add_index "accounts", ["email"], :name => "index_accounts_on_email", :unique => true
  add_index "accounts", ["reset_password_token"], :name => "index_accounts_on_reset_password_token", :unique => true

  create_table "addresses", :force => true do |t|
    t.integer  "geopin"
    t.integer  "address_id"
    t.integer  "street_id"
    t.string   "house_num"
    t.string   "street_name"
    t.string   "street_type"
    t.string   "address_long"
    t.string   "case_district"
    t.float    "x"
    t.float    "y"
    t.string   "status"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
    t.string   "parcel_id"
    t.boolean  "official"
    t.string   "street_full_name"
    t.string   "assessor_url"
    t.integer  "neighborhood_id"
    t.spatial  "point",            :limit => {:srid=>-1, :type=>"geometry"}
    t.string   "latest_type"
    t.integer  "latest_id"
    t.integer  "double_id"
  end

  add_index "addresses", ["address_long"], :name => "index_addresses_on_address_long"
  add_index "addresses", ["house_num", "street_name"], :name => "index_addresses_on_house_num_and_street_name"

  create_table "admins", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "admins", ["email"], :name => "index_admins_on_email", :unique => true
  add_index "admins", ["reset_password_token"], :name => "index_admins_on_reset_password_token", :unique => true

  create_table "case_managers", :force => true do |t|
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "case_number"
    t.string   "name"
  end

  create_table "cases", :force => true do |t|
    t.string   "case_number"
    t.integer  "geopin"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "address_id"
    t.string   "state"
    t.integer  "status_id"
    t.string   "status_type"
    t.string   "outcome"
  end

  add_index "cases", ["address_id"], :name => "index_cases_on_address_id"
  add_index "cases", ["case_number"], :name => "index_cases_on_case_number"

  create_table "complaints", :force => true do |t|
    t.string   "status"
    t.datetime "date_received"
    t.string   "case_number"
    t.string   "notes"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "spawn_id"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "demolitions", :force => true do |t|
    t.string   "case_number"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.integer  "address_id"
    t.string   "house_num"
    t.string   "street_name"
    t.string   "street_type"
    t.string   "address_long"
    t.string   "zip_code"
    t.string   "program_name"
    t.datetime "date_started"
    t.datetime "date_completed"
    t.integer  "address_match_confidence"
    t.boolean  "case_confidence"
    t.string   "demo_number"
  end

  add_index "demolitions", ["address_id"], :name => "index_demolitions_on_address_id"

  create_table "foreclosures", :force => true do |t|
    t.string   "case_number"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.string   "house_num"
    t.string   "street_name"
    t.string   "street_type"
    t.string   "address_long"
    t.string   "status"
    t.string   "notes"
    t.integer  "address_match_confidence"
    t.integer  "address_id"
    t.datetime "sale_date"
    t.string   "cdc_case_number"
    t.string   "title"
    t.string   "defendant"
    t.string   "plaintiff"
    t.boolean  "case_confidence"
  end

  add_index "foreclosures", ["address_id"], :name => "index_foreclosures_on_address_id"

  create_table "hearings", :force => true do |t|
    t.datetime "hearing_date"
    t.string   "hearing_status"
    t.boolean  "reset_hearing"
    t.integer  "one_time_fine"
    t.integer  "court_cost"
    t.integer  "recordation_cost"
    t.integer  "hearing_fines_owed"
    t.integer  "daily_fines_owed"
    t.integer  "fines_paid"
    t.datetime "date_paid"
    t.integer  "amount_still_owed"
    t.integer  "grace_days"
    t.datetime "grace_end"
    t.string   "case_manager"
    t.integer  "tax_id"
    t.string   "case_number"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "hearing_type"
    t.boolean  "is_complete"
    t.integer  "spawn_id"
  end

  add_index "hearings", ["case_number"], :name => "index_hearings_on_case_number"

  create_table "inspection_findings", :force => true do |t|
    t.integer  "inspection_id"
    t.text     "finding"
    t.string   "label"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "inspections", :force => true do |t|
    t.string   "case_number"
    t.string   "result"
    t.datetime "scheduled_date"
    t.datetime "inspection_date"
    t.string   "inspection_type"
    t.integer  "inspector_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.text     "notes"
    t.integer  "spawn_id"
  end

  add_index "inspections", ["case_number"], :name => "index_inspections_on_case_number"

  create_table "inspectors", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "judgements", :force => true do |t|
    t.string   "case_number"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "status"
    t.string   "notes"
    t.datetime "judgement_date"
    t.integer  "spawn_id"
  end

  add_index "judgements", ["case_number"], :name => "index_judgements_on_case_number"

  create_table "maintenances", :force => true do |t|
    t.string   "house_num"
    t.string   "street_name"
    t.string   "street_type"
    t.string   "address_long"
    t.string   "program_name"
    t.datetime "date_recorded"
    t.datetime "date_completed"
    t.string   "status"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.integer  "address_id"
    t.integer  "address_match_confidence"
    t.boolean  "case_confidence"
    t.string   "case_number"
  end

  add_index "maintenances", ["address_id"], :name => "index_maintenances_on_address_id"

  create_table "neighborhoods", :force => true do |t|
    t.string   "name"
    t.float    "x_min"
    t.float    "y_min"
    t.float    "x_max"
    t.float    "y_max"
    t.float    "area"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.spatial  "the_geom",   :limit => {:srid=>-1, :type=>"geometry"}
  end

  create_table "notifications", :force => true do |t|
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "case_number"
    t.date     "notified"
    t.string   "notification_type"
    t.integer  "spawn_id"
  end

  create_table "parcels", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "properties", :force => true do |t|
    t.string   "street"
    t.integer  "number"
    t.integer  "zip_code"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "resets", :force => true do |t|
    t.string   "case_number"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.datetime "reset_date"
    t.string   "notes"
    t.integer  "spawn_id"
  end

  add_index "resets", ["case_number"], :name => "index_resets_on_case_number"

  create_table "searches", :force => true do |t|
    t.text     "term"
    t.string   "ip"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "streets", :force => true do |t|
    t.string   "prefix"
    t.string   "prefix_type"
    t.string   "name"
    t.string   "suffix"
    t.string   "suffix_type"
    t.string   "full_name"
    t.integer  "length_numberic"
    t.integer  "shape_len"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
    t.string   "prefix_direction"
    t.string   "suffix_direction"
    t.spatial  "the_geom",         :limit => {:srid=>-1, :type=>"geometry"}
  end

  create_table "subscriptions", :force => true do |t|
    t.integer  "address_id"
    t.integer  "account_id"
    t.string   "notes"
    t.datetime "created_at",                                              :null => false
    t.datetime "updated_at",                                              :null => false
    t.datetime "date_notified"
    t.spatial  "thegeom",       :limit => {:srid=>-1, :type=>"geometry"}
  end

end
