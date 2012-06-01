class Foreclosure < ActiveRecord::Base
  belongs_to :address
  belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number

  def date
    self.sale_date || DateTime.new(0)
  end

  def self.matched
  	Foreclosure.count(:conditions =>'address_id is not null')
  end

  def self.unmatched
  	Foreclosure.count(:conditions => 'address_id is null')
  end

  def self.pct_matched
  	Foreclosure.count(:conditions => "address_id is not null").to_f / Foreclosure.count.to_f * 100
  end

  def self.status
  	Foreclosure.count(group: :status)
  end
  
end
