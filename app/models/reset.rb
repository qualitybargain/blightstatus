class Reset < ActiveRecord::Base
	belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number

  validates_uniqueness_of :reset_date, :scope => :case_number

  def date
    self.reset_date || DateTime.new(0)
  end

  def self.matchedCount
  	Reset.count(:conditions =>'case_number is not null')
  end

  def self.unmatchedCount
  	Reset.count(:conditions => 'case_number is null')
  end

  def self.pctMatched
  	Reset.count(:conditions => "case_number is not null").to_f / Reset.count.to_f * 100
  end

end
