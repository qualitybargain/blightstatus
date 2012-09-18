class Case < ActiveRecord::Base
  belongs_to :address
	
  has_many :hearings, :foreign_key => :case_number, :primary_key => :case_number
  has_many :inspections, :foreign_key => :case_number, :primary_key => :case_number
  has_many :demolitions, :foreign_key => :case_number, :primary_key => :case_number
  has_many :maintenances, :foreign_key => :case_number, :primary_key => :case_number 
  has_one  :judgement, :foreign_key => :case_number, :primary_key => :case_number
  has_one  :case_manager, :foreign_key => :case_number, :primary_key => :case_number
  has_one  :foreclosure, :foreign_key => :case_number, :primary_key => :case_number
  has_many :resets, :foreign_key => :case_number, :primary_key => :case_number
  has_many :notifications, :foreign_key => :case_number, :primary_key => :case_number
  has_one  :complaint, :foreign_key => :case_number, :primary_key => :case_number

  validates_presence_of :case_number
  validates_uniqueness_of :case_number

  def accela_steps
    steps_ary = []
    steps_ary << self.hearings << self.inspections << self.demolitions << self.resets << self.foreclosure << self.notifications << self.maintenances << self.judgement
    steps_ary.flatten.compact
  end

  def first_status
    self.accela_steps.sort{ |a, b| a.date <=> b.date }.first
  end

  def most_recent_status
    self.accela_steps.sort{ |a, b| a.date <=> b.date }.last
  end

  def most_recent_step_before_abatement
    steps_ary = []
    steps_ary << self.hearings << self.inspections << self.resets  << self.notifications  << self.judgement
    steps_ary.flatten.compact.sort{ |a, b| a.date <=> b.date }.last
  end
  
  def elapsed_time
    most_recent_status.date.to_datetime.mjd - first_status.date.to_datetime.mjd
  end

  def assign_address(options = {})
    if options[:address_long]
      a = Address.where("address_long = ?", options[:address_long])
      if a.length == 1
        self.address = a.first
      elsif a.length > 1 && geopin
        #find by geopin and address
        a = Address.where( "address_long = :address_long AND geopin = :pin_num", {:address_long => options[:address_long], :pin_num => geopin} )
        if a.length == 1
          self.address = a.first
        end
      end
    elsif geopin
      a = Address.where(:geopin => geopin)
      if a.length === 1
        self.address = a.first
      end
    end
    self.save!
  end

  def self.complete
    Case.joins(:hearings, :inspections, :judgement).uniq
  end

  def self.at_inspection
    Case.includes([:hearings, :judgement]).where("hearings.id IS NULL AND judgements.id IS NULL")
  end

  def self.without_inspection
    Case.includes([:inspections]).where("inspections.id IS NULL")
  end

  def self.hearings_without_judgement
    Case.includes([:hearings, :judgement]).where("judgements.id IS NULL AND cases.case_number = hearings.case_number")
  end

  def self.matched_count
    Case.count(:conditions =>'address_id is not null')
  end

  def self.unmatched_count
    Case.count(:conditions => 'address_id is null')
  end

  def self.pct_matched
    Case.matched_count.to_f / Case.count.to_f * 100
  end
   
  def to_hash
    c = {}
    c[:complaint] = self.complaint
    c[:inspections] = self.inspections
    c[:notifications] = self.notifications
    c[:hearings] = self.hearings
    c[:judgement] = self.judgement
    c[:case_manager] = self.case_manager
    c[:resets] = self.resets
    c[:foreclosure] = self.foreclosure
    c[:demolitions] = self.demolitions
    c[:maintenances] = self.maintenances
    c
  end

  def self.incomplete
    Case.find_by_sql("select c.* from cases c where c.case_number in (select case_number from judgements j where not exists(select h.case_number from hearings h where h.case_number = j.case_number)) or c.case_number in (select h.case_number from hearings h where not exists (select * from notifications n where n.case_number = h.case_number)) or c.case_number in (select n.case_number from notifications n where not exists (select * from inspections i where i.case_number = n.case_number)) order by c.case_number").uniq
  end

  def self.orphans
    Case.where(:address_id => nil)
  end
end
