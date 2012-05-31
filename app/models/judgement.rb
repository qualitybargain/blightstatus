class Judgement < ActiveRecord::Base
	belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number

	def self.matchedCount
		Judgement.count(:conditions =>'case_number is not null')
	end

	def self.unmatchedCount
		Judgement.count(:conditions => 'case_number is null')
	end

	def self.pctMatched
		Judgement.count(:conditions => "case_number is not null").to_f / Judgement.count.to_f * 100
	end
	
	def self.status
		Judgement.count(group: :status)
	end

end