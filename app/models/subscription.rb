class Subscription < ActiveRecord::Base
  belongs_to :account
  has_many :addresses 
end
