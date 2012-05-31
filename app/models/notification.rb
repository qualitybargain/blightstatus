class Notification < ActiveRecord::Base
	belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number
  
  validates_uniqueness_of :notified, :scope => [:case_number, :notification_type]

  def date
    self.notified.to_datetime || DateTime.new(0)
  end

  def notes
  	"Notice of Hearing"
  end

  def self.matchedCount
  	Notification.count(:conditions =>'case_number is not null')
  end

  def self.unmatchedCount
  	Notification.count(:conditions => 'case_number is null')
  end

  def self.pctMatched
  	Notification.count(:conditions => "case_number is not null").to_f / Notification.count.to_f * 100
  end

  def self.types
  	Notification.count(group: :notification_type)
  end
end
