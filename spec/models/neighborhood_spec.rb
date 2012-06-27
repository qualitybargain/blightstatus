require 'spec_helper'

describe Neighborhood do
  
  before(:each) do
    @neighborhood = FactoryGirl.create(:neighborhood)
  end

  it { should validate_uniqueness_of(:name) }
  #it { should validate_uniqueness_of(:the_geom) } 	r_spec
end
