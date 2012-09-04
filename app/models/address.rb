class Address < ActiveRecord::Base
  belongs_to :street
  has_many :cases
  has_many :demolitions
  has_many :foreclosures
  has_many :maintenances

  has_many :subscriptions
  has_many :accounts, :through => :subscriptions
  has_many :inspections, :through => :cases
  has_many :notifications, :through => :cases
  has_many :hearings, :through => :cases
  has_many :judgements, :through => :cases

  accepts_nested_attributes_for :subscriptions, :allow_destroy => true

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
    self.cases.sort{ |a, b| ( a.most_recent_status and b.most_recent_status ) ? a.most_recent_status.date <=> b.most_recent_status.date : ( a.most_recent_status ? -1 : 1 ) }
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
    self.most_recent_status.nil? ? {} : {:type => self.most_recent_status.class.to_s, :date => self.most_recent_status.date.strftime('%B %e, %Y')} 
  end

  def self.find_addresses_with_cases_by_street(street_string)
    Address.joins(:cases).where(:addresses => {:street_name => street_string})
  end

  def self.find_addresses_with_cases_by_cardinal_street(card, street_string)
    Address.joins(:cases).where('address_long like ?', '%' + card.single_space + ' ' + street_string.single_space + '%')
  end

  def self.find_addresses_with_cases_within_area(ne, sw)
    factory = Address.first.point.factory
    box = RGeo::Cartesian::BoundingBox.new(factory)
    p1 = factory.point(ne["lng"].to_f, ne["lat"].to_f)
    p2 = factory.point(sw["lng"].to_f, sw["lat"].to_f)
    box.add(p1).add(p2)
    @addresses = Address.find_by_sql("SELECT a.* FROM addresses a INNER JOIN cases c ON c.address_id = a.id WHERE ST_Within(point, ST_GeomFromText('#{box.to_geometry.as_text}')) GROUP BY a.id ORDER BY a.street_name ASC, a.house_num ASC;")
  end
end
