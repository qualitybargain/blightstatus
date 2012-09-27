require "#{Rails.root}/app/helpers/cases_helper.rb"
include CasesHelper

class Inspection < ActiveRecord::Base
  belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number
  belongs_to :inspector
  has_many :inspection_findings

  validates_uniqueness_of :inspection_date, :scope => :case_number

  after_save do
    CasesHelper.update_status(self)
  end

  def date
    self.inspection_date || self.scheduled_date || DateTime.new(0)
  end

  def notes
  	self.result
  end

  def self.matched_count
  	Inspection.count(:conditions =>'case_number is not null')
  end

  def self.unmatched_count
  	Inspection.count(:conditions => 'case_number is null')
  end

  def self.pct_matched
  	Inspection.count(:conditions => "case_number is not null").to_f / Inspection.count.to_f * 100
  end

  def self.types
  	Inspection.count(group: :inspection_type)
  end

  def self.results
  	Inspection.count(group: :inspection_type)
  end
end
