class Foreclosure < ActiveRecord::Base
  belongs_to :address
  belongs_to :case, :foreign_key => :case_number, :primary_key => :case_number

  def date
    self.sale_date || DateTime.new(0)
  end

  def self.matched_count
  	Foreclosure.count(:conditions =>'address_id is not null')
  end

  def self.unmatched_count
  	Foreclosure.count(:conditions => 'address_id is null')
  end

  def self.pct_matched
  	Foreclosure.count(:conditions => "address_id is not null").to_f / Foreclosure.count.to_f * 100
  end

  def self.status
  	Foreclosure.count(group: :status)
  end

  def self.import_from_sheriff(cdc_number)
    client = Savon.client ENV['SHERIFF_WSDL']
    response = client.request 'm:GetForeclosure' do  #:get_foreclosure do
      http.headers['SOAPAction'] = ENV['SHERIFF_ACTION']
      soap.namespaces['xmlns:m'] = ENV['SHERIFF_NS']
      soap.body = {'m:cdcCaseNumber' => cdc_number, 'm:key' => ENV['SHERIFF_PASSWORD'] }
    end

    foreclosure = response.hash[:envelope][:body][:get_foreclosure_response][:get_foreclosure_result][:foreclosure]
    address = foreclosure[:property_address].split ","

    f = Foreclosure.new
    if (address)
      addr_long = addr[:address_long]
      f.house_num = address.first.strip
      f.address_long = address.join(" ").single_space
      street_info = address.pop.strip
      f.street_type = AddressHelpers.get_street_type(addr_long)
      f.street_name = AddressHelpers.get_street_name(addr_long)
    end
    f.status = foreclosure[:sale_status]
    f.sale_date = DateTime.strptime(foreclosure[:sale_date], '%m/%d/%Y %H:%M:%S %p')
    f.title = foreclosure[:case_title]
    f.cdc_case_number = foreclosure[:cdc_case_number]
    f.defendant = foreclosure[:defendant]
    f.plantiff = foreclosure[:plantiff]
    f.save
  end
  
end
