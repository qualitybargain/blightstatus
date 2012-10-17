require "#{Rails.root}/lib/lama_helpers.rb"
require "#{Rails.root}/lib/address_helpers.rb"
include LAMAHelpers
include AddressHelpers

class Address < ActiveRecord::Base
  belongs_to :neighborhood
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

  has_one :double_address, :class_name => "Address", :foreign_key => :double_id

  accepts_nested_attributes_for :subscriptions, :allow_destroy => true

  validates_uniqueness_of :address_id

  scope :updated_since, lambda { |time| where("updated_at > ?", time) }

  def cardinal
    if address_long.match(' (W|E|N|S) ')
      $1
    end
  end

  def latest_status
    latest_step = nil
    if latest_id
      begin
        latest_step = Kernel.const_get(latest_type).find(latest_id)
      rescue ActiveRecord::RecordNotFound
        self.update_attributes(:latest_id => nil, :latest_type => nil)
      end
    elsif !self.workflow_steps.empty?
      latest_step = self.workflow_steps.sort{ |a, b| a.date <=> b.date }.last
      self.update_attributes({:latest_id => latest_step.id, :latest_type => latest_step.class.to_s})
    end
    return latest_step
  end

  def most_recent_status
    latest_status
  end

  def update_most_recent_status(status)
    if (self.most_recent_status.nil?) || (self.most_recent_status.date < status.date)
      self.update_attributes({latest_id: status.id, latest_type: status.class.to_s})
    end
  end

  def most_recent_status_preview
    self.most_recent_status.nil? ? {} : {:type => self.most_recent_status.class.to_s, :date => self.most_recent_status.date.strftime('%B %e, %Y')} 
  end

  def resolutions
    res_ary = []
    res_ary << self.foreclosures << self.demolitions << self.maintenances
    res_ary.flatten.compact
  end

  def set_assessor_link
    url = "http://qpublic4.qpublic.net/la_orleans_display.php?KEY=#{house_num}-#{cardinal}#{street_name}#{street_type}".gsub(" ", "")
    page = Net::HTTP.get(URI(url))
    self.update_attributes(:assessor_url => url) unless page.match(/No Data at this time/)
  end

  def sorted_cases
    self.cases.sort{ |a, b| ( a.most_recent_status and b.most_recent_status ) ? a.most_recent_status.date <=> b.most_recent_status.date : ( a.most_recent_status ? -1 : 1 ) }
  end

  def cases_sorted_by_state
    self.cases.sort{|a,b| b.case_steps <=> a.case_steps}
  end

  def workflow_steps
    steps_ary = []
    self.cases.each do |c|
      steps_ary << c.accela_steps
    end
    steps_ary << self.resolutions
    steps_ary.flatten.compact
  end

  def assign_double
    return unless self.double_address.nil?
    d = Address.where("x = ? AND y = ?", self.x, self.y).first
    self.double_address = d
    d.double_address = self
    save
    d.save
  end

  def self.find_addresses_with_cases_by_cardinal_street(card, street_string)
    Address.joins(:cases).where('address_long like ?', '%' + card.single_space + ' ' + street_string.single_space + '%')
  end

  def self.find_addresses_with_cases_by_street(street_string)
    Address.joins(:cases).where(:addresses => {:street_name => street_string})
  end

  def self.find_addresses_with_cases_within_area(ne, sw)
    factory = Address.first.point.factory
    box = RGeo::Cartesian::BoundingBox.new(factory)
    p1 = factory.point(ne["lng"].to_f, ne["lat"].to_f)
    p2 = factory.point(sw["lng"].to_f, sw["lat"].to_f)
    box.add(p1).add(p2)
    @addresses = Address.find_by_sql("SELECT a.id, a.geopin, a.house_num, a.street_name, a.street_type, a.address_long, a.point FROM addresses a INNER JOIN cases c ON c.address_id = a.id WHERE ST_Within(point, ST_GeomFromText('#{box.to_geometry.as_text}')) GROUP BY a.id, a.geopin, a.house_num, a.street_name, a.street_type, a.address_long, a.point ORDER BY a.street_name ASC, a.house_num ASC;")
  end

  def self.find_addresses_with_cases_by_neighborhood(neighborhood_name)
    Address.joins(:cases,:neighborhood).where(:neighborhoods => {:name => neighborhood_name})
  end

  def self.find_doubles
    Address.all.find_each do |address|
      address.assign_double
    end
  end

  def load_cases
    LAMAHelpers.import_by_location(self.address_long)
  end
end
