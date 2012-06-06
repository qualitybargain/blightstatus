class Address < ActiveRecord::Base
  belongs_to :street
  has_many :cases
  has_many :demolitions
  has_many :foreclosures
  has_many :maintenances

  has_many :subscriptions
  has_many :accounts, :through => :subscriptions
  accepts_nested_attributes_for :subscriptions, :allow_destroy => true
  

  has_many :inspections, :through => :cases
  has_many :notifications, :through => :cases
  has_many :hearings, :through => :cases
  has_many :judgements, :through => :cases

  validates_uniqueness_of :address_id

  def workflow_steps
    steps_ary = []
    self.cases.each do |c|
      steps_ary << c.accela_steps
    end
    steps_ary << self.resolutions
    steps_ary.flatten.compact
  end

  def resolutions
    res_ary = []
    res_ary << self.foreclosures << self.demolitions << self.maintenances
    res_ary.flatten.compact
  end

  def most_recent_status
    !self.workflow_steps.empty? ? self.workflow_steps.sort{ |a, b| a.date <=> b.date }.last : nil
  end

  def sorted_cases
    self.cases.sort{ |a, b| a.most_recent_status.date <=> b.most_recent_status.date }
  end

  def cardinal
    if address_long.match(' (W|E|N|S) ')
      $1
    end
  end

  def set_assessor_link
    url = "http://qpublic4.qpublic.net/la_orleans_display.php?KEY=#{house_num}-#{cardinal}#{street_name}#{street_type}".gsub(" ", "")
    page = Net::HTTP.get(URI(url))
    self.update_attributes(:assessor_url => url) unless page.match(/No Data at this time/)
  end

  def most_recent_status_preview
    s = self.most_recent_status
    {:type => s.class.to_s, :date => s.date.strftime('%B %e, %Y')}
  end

  def self.find_addresses_with_cases_by_street(street_string)
    Address.joins(:cases).where(:addresses => {:street_name => street_string})
  end

end
