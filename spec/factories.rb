FactoryGirl.define do
  factory :address do
    # address_id        { 424704 }
    # parcel_id         { 1 + rand(20000) }
    # geopin            { 1 + rand(30000) }
    geopin            { 41125604 }
    address_id        { 1 + rand(20000) } #{ 85102061 }
    # parcel_id         { 1 + rand(20000) }
    address_long      { "1019 CHARBONNET ST" }
    street_name       { "CHARBONNET" }
    street_type       { "ST" }
  end


  factory :case do
    case_number       { "CEHB " + rand(1000).to_s()}
  end

  factory :demolition do
    #date_started      {Time.now - 2.days}
    #date_completed    {Time.now - 1.days}
  end

  factory :foreclosure do
  end

  factory :hearing do
    hearing_date      { DateTime.new(rand(1000)) }
  end

  factory :inspection do
    inspection_type   { "Violation Posted No WIP" }
  end
  factory :judgement do
  end
  factory :maintenance do
  end
  factory :notification do
    #are there any fields to require?
  end
  factory :reset do
    reset_date {DateTime.new(rand(1000))}
  end
  factory :street do
    #name       { "CHARBONNET" }
  end
end
