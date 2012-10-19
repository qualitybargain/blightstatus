class Account < ActiveRecord::Base
  attr_accessible :email, :password, :password_confirmation, :remember_me, :send_notifications

  has_many :subscriptions
  has_many :addresses, :through => :subscriptions

  accepts_nested_attributes_for :subscriptions, :allow_destroy => true

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  include Devise::Async::Model

  validates_presence_of :email

  def send_digest
    if send_notifications
      subs = subscriptions.select{ |s| s.updated_since_last_notification? }
      if subs.length > 0
        t = Time.now
        subs.each{ |s| s.update_attribute(:date_notified, t) }
        AccountMailer.delay.deliver_digest(self, subs)
      end
    end
  end
end
