class Account < ActiveRecord::Base
  has_many :subscriptions

  has_many :addresses, :through => :subscriptions
  accepts_nested_attributes_for :subscriptions, :allow_destroy => true

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  def subscribed_addresses
    #addresses
  end



end
