class Judgement < ActiveRecord::Base
	belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number
	validates_uniqueness_of :judgement_date, :scope => :case_number  
  
  after_save do
    if self.case
      self.case.update_status(self)
    end
  end

  after_destroy do
    if self.case
      self.case.update_last_status
    end
  end

  def date
    self.judgement_date || Time.now
  end

	def self.matched_count
		Judgement.count(:conditions =>'case_number is not null')
	end

	def self.unmatched_count
		Judgement.count(:conditions => 'case_number is null')
	end

	def self.pct_matched
		Judgement.count(:conditions => "case_number is not null").to_f / Judgement.count.to_f * 100
	end
	
	def self.status
		Judgement.count(group: :status)
	end

	def self.without_hearings
		Judgement.find_by_sql("select j.* from judgements j where not exists (select * from hearings h where h.case_number = j.case_number)")
	end
end
