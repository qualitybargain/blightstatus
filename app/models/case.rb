  class Case < ActiveRecord::Base
  after_save :update_address_status

  belongs_to :address

  has_many :hearings, :foreign_key => :case_number, :primary_key => :case_number
  has_many :inspections, :foreign_key => :case_number, :primary_key => :case_number
  has_many :notifications, :foreign_key => :case_number, :primary_key => :case_number

  has_many :demolitions, :foreign_key => :case_number, :primary_key => :case_number
  has_many :maintenances, :foreign_key => :case_number, :primary_key => :case_number 

  has_many :judgements, :foreign_key => :case_number, :primary_key => :case_number
  has_one  :case_manager, :foreign_key => :case_number, :primary_key => :case_number
  has_one  :foreclosure, :foreign_key => :case_number, :primary_key => :case_number
  has_many :resets, :foreign_key => :case_number, :primary_key => :case_number
  has_one  :complaint, :foreign_key => :case_number, :primary_key => :case_number

  validates_presence_of :case_number
  validates_uniqueness_of :case_number

  def first_inspection
    self.ordered_inspections.first
  end

  def last_inspection
    self.ordered_inspections.last
  end

  def last_hearing
    self.ordered_hearings.last
  end

  def ordered_hearings
    self.hearings.sort{ |a, b| b.date <=> a.date }
  end

  def ordered_inspections
    self.inspections.sort{ |a, b| b.date <=> a.date }
  end

  def ordered_case_steps
    case_steps = []
    case_steps << self.inspections << self.hearings << self.notifications << self.judgements << (self.demolitions || self.foreclosure || self.maintenances )
    case_steps.flatten.compact
  end


  def ordered_hearings_and_judgements
    case_steps = []
    case_steps << self.hearings << self.judgements
    case_steps.flatten.compact.sort{ |a, b| a.date <=> b.date }

  end

  def accela_steps
    steps_ary = []
    steps_ary << self.hearings << self.inspections << self.demolitions << self.resets << self.foreclosure << self.notifications << self.maintenances << self.judgement
    steps_ary.flatten.compact
  end

  def first_status
    self.accela_steps.sort{ |a, b| a.date <=> b.date }.first
  end

  def last_status
    self.ordered_case_steps.last
  end

  def status
    step = nil
    if self.status_type && self.status_id 
      begin
        step = Kernel.const_get(status_type).find(status_id)
      rescue ActiveRecord::RecordNotFound
        self.update_attributes({:status_id => nil, :status_type => nil })
      end
    else
      step = update_last_status
    end
    return step
  end

  def most_recent_status
    self.status
  end

  def update_status(step)
    latest = most_recent_status
    if latest.nil? || step.date >= latest.date
      self.update_attributes({:status_id => step.id, :status_type => step.class.to_s })
    end
  end

  def update_last_status
    if !adjudication_steps.empty?
      step = adjudication_steps.last
      self.update_attributes({:status_id => step.id, :status_type => step.class.to_s })
      return step
    elsif status_id != nil && status_type != nil
      self.update_attributes({:status_id => nil, :status_type => nil })
    end
  end

  def update_address_status
    if self.address && self.most_recent_status
      self.address.update_most_recent_status(self.most_recent_status)
    end
  end

  def name_of_most_recent_status
    self.most_recent_status.class.to_s
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
    Case.joins(:hearings, :inspections, :judgements).uniq
  end

  def self.at_inspection
    Case.includes([:hearings, :judgements]).where("hearings.id IS NULL AND judgements.id IS NULL")
  end

  def self.without_inspection
    Case.includes([:inspections]).where("inspections.id IS NULL")
  end

  def self.hearings_without_judgement
    Case.includes([:hearings, :judgements]).where("judgements.id IS NULL AND cases.case_number = hearings.case_number")
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
    c[:judgements] = self.judgement
    c[:case_manager] = self.case_manager
    c[:resets] = self.resets
    c[:foreclosure] = self.foreclosure
    c[:demolitions] = self.demolitions
    c[:maintenances] = self.maintenances
    c
  end

  def case_steps
    case_steps = []
    case_steps << self.inspections.first << self.hearings.first   << self.notifications.first << self.judgement << (self.demolitions || self.foreclosure || self.maintenances )
    case_steps.flatten.compact.count
  end

  def adjudication_steps
    steps_ary = []
    steps_ary << self.inspections(true) << self.notifications(true) << self.hearings(true) << self.judgement << self.resets(true) 
    steps_ary.flatten.compact.sort{ |a, b| a.date <=> b.date }
  end

  def case_data_error?

    if case_steps == 1 && missing_inspection?
      true
    elsif case_steps == 2 && missing_notification?
      true
    elsif case_steps == 3 && missing_hearing? 
      true
    elsif case_steps == 4 && missing_judgement?
      true
    elsif case_steps == 5 && missing_resolution?
      true
    end
  end


  #this sucks. but no other way to do this now. discussions of our new data model will make this obsolete

  def missing_inspection?
    # if the current is empty
    self.inspections.empty? && 

    # and and of the future steps are not empty
    ( !self.notifications.empty? || !self.hearings.empty? || !self.judgement.nil?  )
  end


  def missing_notification?
    # if the current is empty
    self.notifications.empty? && 

    (    
      # the previous step is empty 
      ( self.inspections.empty?) ||
      # OR future steps are not emptry
      ( !self.hearings.empty? || !self.judgement.nil?  )
    )

  end

  def missing_hearing?
    # if the current is empty
    self.hearings.empty? && 

    (    
      # the previous step is empty 
      !( self.inspections.empty? || self.notifications.empty? ) || 
      # OR future steps are not emptry
      ( !self.judgement.nil?  )
    )
  end


  def missing_judgement?

    # if the current is empty
    self.judgement.nil? && 

    (    
      # the previous step is empty
      !( self.inspections.empty? || self.notifications.empty? || self.hearings.empty? ) || 
      # OR future steps are not emptry
      ( !self.demolitions.empty?  )
    )

  end

  def missing_resolution?
    
    !( self.inspections.empty? || self.notifications.empty? || self.hearings.empty? || self.judgement.nil? ) 
  end


  def resolutions
    res_ary = []
    res_ary << self.demolitions << self.maintenances << self.foreclosure
    res_ary.flatten.compact
  end


  def self.incomplete
    Case.find_by_sql("select c.* from cases c where c.case_number in (select case_number from judgements j where not exists(select h.case_number from hearings h where h.case_number = j.case_number)) or c.case_number in (select h.case_number from hearings h where not exists (select * from notifications n where n.case_number = h.case_number)) or c.case_number in (select n.case_number from notifications n where not exists (select * from inspections i where i.case_number = n.case_number)) order by c.case_number").uniq
  end

  def self.orphans
    Case.where(:address_id => nil)
  end

  def self.missing
    #ratings = Complaint.where(:case_number not inselect(:case_number).uniq
    case_numbers = []
    case_numbers << Judgement.find_by_sql('select j.case_number from judgements j where j.case_number not in (select c.case_number from cases c where c.case_number = j.case_number)')#.select(:case_number)
    case_numbers << Hearing.find_by_sql('select h.case_number from hearings h where h.case_number not in (select c.case_number from cases c where c.case_number = h.case_number)')#.select(:case_number)
    case_numbers << Inspection.find_by_sql('select i.case_number from inspections i where i.case_number not in (select c.case_number from cases c where c.case_number = i.case_number)')#.select(:case_number)
    case_numbers << Notification.find_by_sql('select n.case_number from notifications n where n.case_number not in (select c.case_number from cases c where c.case_number = n.case_number)')
    case_numbers << Complaint.find_by_sql('select k.case_number from complaints k where k.case_number not in (select c.case_number from cases c where k.case_number = k.case_number)')
    case_numbers.flatten!  

    case_numbers.map! {|x| x.case_number}
    case_numbers.uniq!
    cases = case_numbers.map {|case_number| Case.new(:case_number => case_number)}
    cases
  end

  def judgement
    self.judgements.last
  end
end
