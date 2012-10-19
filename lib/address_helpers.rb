#move this to better spot
class String
  def single_space
    self.split.join(' ').strip
  end
end

module AddressHelpers

  @street_types = {'ST' => "STREET", 'AVE' => "AVENUE", 'DR'=> 'DRIVE', 'CT'=> "COURT", 'RD'=> 'ROAD', "LN" => 'LANE', 'PL' => 'PLACE', 'PARK' => 'PARK', 'BLVD' => 'BOULEVARD', 'ALY' => 'ALLEY', 'PKWY' => 'PARKWAY'}
  @street_direction = {'S' => 'SOUTH', 'N' => 'NORTH', 'E' => 'EAST', 'W' => 'WEST'}
  @address_suffix = ['ACC','GARAGE', 'ACC BD','MAIN', 'ACC STR']

  # DRY NOT AT WORK HERE
  # WE SHOULD COMPRESS THESE FUNCTIONS

  def abbreviate_street_types(streetname)
    streetname.upcase!
    @street_types.each do |(label, value)|
      if streetname.match(/#{value}$/)
        return streetname.sub(/#{value}$/, label)
      end
    end
    return streetname
  end

  def unabbreviate_street_types(streetname)
    streetname.upcase!
    @street_types.each do |(label, value)|
      if streetname.match(/\s#{label}$/)
        return streetname.sub(/\s#{label}$/, " #{value}")
      end
    end
    return streetname
  end

  def abbreviate_street_direction(streetname)
    streetname.upcase!
    @street_direction.each do |(label, value)|
      if streetname.match(/\s#{value}\s/)
        return streetname.sub(/\s#{value}\s/, " #{label} ")
      elsif streetname.match(/#{value}\s/)
        return streetname.sub(/#{value}\s/, "#{label} ")
      end
    end
    return streetname
  end

  def unabbreviate_street_direction(streetname)
    streetname.upcase!
    @street_direction.each do |(label, value)|
      if streetname.match(/\s#{label}\s/)
        return streetname.sub(/\s#{label}\s/, " #{value} ")
      end
    end
    return streetname
  end

  def get_street_type(streetname)
    streetname.upcase!
    @street_types.each do |(label, value)|
      if !streetname.match(/#{label}$/).nil? || !streetname.match(/#{value}$/).nil?
        return label
      end
    end
    return streetname
  end


  def get_street_name(streetname)
    streetname = streetname.to_s.single_space.upcase
    streetname = strip_address_number(streetname)
    streetname = strip_address_unit(streetname)
    streetname = strip_direction(streetname)
    
    
    unless streetname.nil?
      @street_types.each do |(label, value)|
        if streetname.match(/\s#{label}$/)
          return streetname.sub(/\s#{label}$/, '').single_space
        elsif streetname.match(/\s#{value}$/)
          return streetname.sub(/\s#{value}$/, '').single_space
        end
      end
    end
    return streetname
  end

  def strip_address_number(streetname)
    if streetname.match(/^\d+\s/)
      return streetname.sub(/^\d+\s/, '')
    end
    return streetname
  end

  def strip_address_unit(streetname)
    streetname = streetname.upcase.sub(/\,.+/, '')
    if streetname.match(/^\d+\-\d+\s/)
      # pair programming at it's best!
      # this is a weird mix of splits and regxp.
      return streetname.sub("-" + streetname.split(',')[0].split(' ')[0].split('-')[1], "")
    end 
    return streetname
  end

  def strip_direction(streetname)
    streetname.upcase!
    @street_direction.each do |(abbr, full)|
      if streetname.match(/(^|\s)#{abbr}(\s|$)/)
        return streetname.sub(/(^|\s)#{abbr}(\s|$)/, ' ')
      end
      if streetname.match(/(^|\s)#{full}(\s|$)/)
        return streetname.sub(/(^|\s)#{full}(\s|$)/, ' ')
      end
    end
    return streetname
  end
  def get_short_direction(streetname)
      if(dir = get_direction(streetname))
        return dir[0]
      end
      return nil
  end
  def get_direction(streetname)
    streetname.upcase!
    @street_direction.each do |(abbr, full)|
      if streetname.match(/(^|\s)#{abbr}(\s|$)/)
        return streetname[/(^|\s)#{abbr}(\s|$)/].strip
      end
      if streetname.match(/(^|\s)#{full}(\s|$)/)
        return streetname[/(^|\s)#{full}(\s|$)/].strip
      end
    end
    return nil
  end

  def strip_suffix(streetname)
    streetname.upcase!
    @address_suffix.each do |value|
      if streetname.match(/\s#{value}$/)
        return streetname.sub(/\s#{value}$/, '') 
      end
    end
    return streetname
  end

  def strip_cruft(streetname)
    streetname.upcase!
    return streetname.sub('ACCES BLD', '').sub('NEAR', '').sub(/\[.+\]/, '').sub(/\(.+\)/, '').single_space
  end

  def strip_special_char(streetname)
    return streetname.gsub(/[\,\.]/, ' ')
  end


  def get_neighborhood(lat,long)
    uri = URI.parse("http://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{long}&sensor=true")
    response = Net::HTTP.get(uri)
    result = JSON.parse(response)
  end

  def find_address(orig_address)
    return [] if orig_address.nil?
    address_string = strip_special_char(orig_address.upcase.single_space)

    address = Address.where("address_long = ?", "#{address_string}")
    return address if !address.empty?

    # if there is no direct hit, then we look for units in the address
    # and strip the unit number
    address_string = strip_address_unit(address_string)
    address = Address.where("address_long = ?", "#{address_string}")
    return address if !address.empty?

    # first we match just by abbriviating street suffixes
    # if we match we return
    address_string = unabbreviate_street_types(address_string)
    address = Address.where("address_long = ?", "#{address_string}")
    return address if !address.empty?

    # first we match just by abbriviating street suffixes
    # if we match we return
    address_string = abbreviate_street_types(address_string)
    address = Address.where("address_long = ?", "#{address_string}")
    return address if !address.empty?

    address_string = abbreviate_street_direction(address_string)
    address = Address.where("address_long = ?", "#{address_string}")
    return address if !address.empty?

    address_string = strip_cruft(address_string)
    address = Address.where("address_long = ?", "#{address_string}")
    return address if !address.empty?

    address_string = strip_suffix(address_string)
    address_street = get_street_name(address_string)
    address = Address.where("house_num = ? and street_name = ?", "#{address_string.split(' ')[0]}", "#{address_street}")
    return address if !address.empty?

    address_string = strip_direction(address_string)
    address_street = get_street_name(address_string)
    address = Address.where("house_num = ? and street_name = ?", "#{address_string.split(' ')[0]}", "#{address_street}")
    return address if !address.empty?

    puts "----NOT FOUND------. Original address: #{orig_address}            Processed address: #{address_string}"
    []
  end

  def find_address_by_geopin(geopin)
    address = Address.where("geopin = ?", geopin)
    !address.empty? ? address : []
  end
end
