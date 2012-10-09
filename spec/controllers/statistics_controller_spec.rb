require 'spec_helper'

describe StatisticsController do
  describe "GET browse" do
    it "returns a response" do
      get 'browse'
      response.should be_success
    end
  end
end
