class Hearing < ActiveRecord::Base
	belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number

  validates_uniqueness_of :hearing_date, :scope => :case_number

  after_save do
    if self.case
      self.case.update_status(self)
    end
  end

  # after_destroy do
  #   if self.case
  #     self.case.update_last_status
  #   end
  # end

  def date
    self.hearing_date || DateTime.new(0)
  end

  def self.matched_count
  	Hearing.count(:conditions =>'case_number is not null')
  end

  def self.unmatched_count
  	Hearing.count(:conditions => 'case_number is null')
  end

  def self.pct_matched
  	Hearing.count(:conditions => "case_number is not null").to_f / Hearing.count.to_f * 100
  end

  def self.status
  	Hearing.count(group: :hearing_status)
  end

  def self.without_notification
    Hearing.find_by_sql("select h.* from hearings h where not exists (select * from notifications n where n.case_number = h.case_number)")
  end
end
