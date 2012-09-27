require "#{Rails.root}/app/helpers/cases_helper.rb"
include CasesHelper

class Notification < ActiveRecord::Base
	belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number
  
  validates_uniqueness_of :notified, :scope => [:case_number, :notification_type]

  after_save do
    CasesHelper.update_status(self)
  end

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

  def self.results
    Notification.count(group: :notification_type)
  end

  def self.without_inspection
    Hearing.find_by_sql("select n.* from notifications n where not exists (select * from inspections i where i.case_number = n.case_number)")
  end
end
