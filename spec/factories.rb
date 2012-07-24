FactoryGirl.define do
  factory :address do
    # geopin            { 1 + rand(30000) }
    geopin            { 41125604 }
    address_id        { 1 + rand(20000) } #{ 85102061 }
    # parcel_id         { 1 + rand(20000) }
    address_long      { "1019 CHARBONNET ST" }
    street_name       { "CHARBONNET" }
    street_type       { "ST" }
    point             {"POINT (-90.04223467290467 29.975021724674335)"}
  end

  factory :case do
    case_number       { "CEHB-" + rand(1000).to_s()}
  end

  factory :demolition do
    #date_started      {Time.now - 2.days}
    #date_completed    {Time.now - 1.days}
  end

  factory :foreclosure do
    sale_date {DateTime.now - 2.days}
  end

  factory :hearing do
    hearing_date      { DateTime.new(rand(1000)) }
  end

  factory :inspection do
    inspection_type   { "Violation Posted No WIP" }
    inspection_date   { DateTime.new(rand(1000)) }
    scheduled_date    { DateTime.new(rand(1000)) }
  end

  factory :inspector do
    name              {"In Spector"}
  end

  factory :judgement do
    status            {"guilty"}
  end

  factory :maintenance do
    date_recorded   { DateTime.new(rand(1000)) }
    date_completed  { DateTime.new(rand(1000)) }
  end

  factory :neighborhood do
    name       { "HOOD " + rand(1000).to_s()}
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
