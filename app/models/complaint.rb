class Complaint < ActiveRecord::Base
  belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number
  validates_uniqueness_of :date_received, :scope => :case_number
  
  after_save do
    self.case.update_last_step(self)
  end
  
  def date
    self.date_received || DateTime.new(0)
  end

end