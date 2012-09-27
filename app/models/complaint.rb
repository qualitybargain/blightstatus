class Complaint < ActiveRecord::Base
  belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number
  validates_uniqueness_of :date_received, :scope => :case_number
  
  after_save do
    kase = self.case
    if kase
      step = kase.most_recent_status
      if self.date >= step.date
        kase.status = self.class.to_s
        kase.save
      end
    end
  end
  
  def date
    self.date_received || DateTime.new(0)
  end

end