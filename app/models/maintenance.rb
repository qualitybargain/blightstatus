class Maintenance < ActiveRecord::Base
  #this is for abatement programs like INAP
  after_save :update_address_status

  belongs_to :address

  def date
    self.date_completed || DateTime.new(0)
  end

  def update_address_status
    if self.address
      self.address.update_most_recent_status(self)
    end
  end

  def self.import_from_workbook(workbook, sheet)
    sheet.each do |row|
      begin
        r_date = workbook.num_to_date(row[5].value.to_i)
        c_date = workbook.num_to_date(row[7].value.to_i)
        Maintenance.create(:house_num => row[0].value, :street_name => row[1].value, :street_type => AddressHelpers.get_street_type(row[2].value), :address_long => AddressHelpers.abbreviate_street_types(row[3].value), :date_recorded => r_date, :date_completed => c_date, :program_name => row[10].value, :status => row[9].value)
      rescue
        p "Maintenance could not be saved: #{$!}"
        p row
      end
    end
  end

  def self.matched_count
    Maintenance.count(:conditions =>'address_id is not null')
  end

  def self.unmatched_count
    Maintenance.count(:conditions => 'address_id is null')
  end

  def self.pct_matched
    Maintenance.count(:conditions => "address_id is not null").to_f / Maintenance.count.to_f * 100
  end

  def self.program_names
    Maintenance.count(group: :program_name)
  end

  def self.status
    Maintenance.count(group: :status)
  end

end
