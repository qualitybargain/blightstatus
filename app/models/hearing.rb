class Hearing < ActiveRecord::Base
	belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number

  validates_uniqueness_of :hearing_date, :scope => :case_number

  def date
    self.hearing_date || DateTime.new(0)
  end

  def self.matchedCount
  	Hearing.count(:conditions =>'case_number is not null')
  end

  def self.unmatchedCount
  	Hearing.count(:conditions => 'case_number is null')
  end

  def self.pctMatched
  	Hearing.count(:conditions => "case_number is not null").to_f / Hearing.count.to_f * 100
  end

  def self.status
  	Hearing.count(group: :hearing_status)
  end
end
