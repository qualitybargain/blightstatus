class Reset < ActiveRecord::Base
	belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number

  validates_uniqueness_of :reset_date, :scope => :case_number

  def date
    self.reset_date || DateTime.new(0)
  end

  def self.matched_count
  	Reset.count(:conditions =>'case_number is not null')
  end

  def self.unmatched_count
  	Reset.count(:conditions => 'case_number is null')
  end

  def self.pct_matched
  	Reset.count(:conditions => "case_number is not null").to_f / Reset.count.to_f * 100
  end

end
