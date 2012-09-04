require 'spec_helper'

describe StatisticsController do

  describe "GET graphs" do
    it "returns a response" do
      get 'graphs'
      response.should be_success
    end
  end

end
