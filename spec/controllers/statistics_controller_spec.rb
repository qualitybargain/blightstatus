require 'spec_helper'

describe StatisticsController do

  describe "GET index" do
    it "returns a response" do
      get 'graphs'
      response.should be_success
    end
  end


  describe "GET index" do
    it "returns a response" do
      get 'maps'
      response.should be_success
    end
  end


end
