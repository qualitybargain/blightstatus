require 'spec_helper'

describe Street do
  pending "add some examples to (or delete) #{__FILE__}"

  describe "#find_like" do
   it "should return array of streets that contains a substring" do
   	  FactoryGirl.create(:street, :name => "CHARBONNET")
      result = Street.find_like("ARBON")
      result.count.should > 0
    end
  end
end
