class Demolition < ActiveRecord::Base
  belongs_to :address
  belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number

  after_save do
    self.case.update_last_step(self)
  end

  def date
    self.date_completed || self.date_started || DateTime.new(0)
  end

  def self.matched_count
  	Demolition.count(:conditions =>'address_id is not null')
  end

  def self.unmatched_count
  	Demolition.count(:conditions => 'address_id is null')
  end

  def self.pct_matched
  	Demolition.count(:conditions => "address_id is not null").to_f / Demolition.count.to_f * 100
  end

end
