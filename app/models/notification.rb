class Notification < ActiveRecord::Base
	belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number
  
  validates_uniqueness_of :notified, :scope => [:case_number, :notification_type]

  def date
    return DateTime.new(0) if notified.nil?
    
    self.notified.to_datetime
  end

  def notes
  	"Notice of Hearing"
  end

  def self.matched_count
  	Notification.count(:conditions =>'case_number is not null')
  end

  def self.unmatched_count
  	Notification.count(:conditions => 'case_number is null')
  end

  def self.pct_matched
  	Notification.count(:conditions => "case_number is not null").to_f / Notification.count.to_f * 100
  end

  def self.types
  	Notification.count(group: :notification_type)
  end
end
