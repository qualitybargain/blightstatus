require 'spec_helper'

describe AddressesController do

  before do
    @address = FactoryGirl.create(:address)
  end

  describe "GET index" do
    it "assigns all addresses as @address" do
      get :index
      response.should be_success
    end
  end

  describe "GET addresses_with_case" do
    it "returns a json of addresses with inspections in the last 2 weeks" do
      get :addresses_with_case, :format => :json, :type => "inspections"
      response.should be_success
    end
  end

  describe "GET show" do
    it "assigns the request address as @address" do
      get :show, :id => @address.id
      assigns(:address).should eq(@address)
    end
  end

  describe "GET search" do
    it "matches the full address if it's given" do
      get :search, :address => "1019 CHARBONNET ST"
      response.should redirect_to(address_path(@address))
    end

    it "matches the street name if no number is given and the searched address has a case" do
      c = FactoryGirl.create(:case, :address_id => @address.id)

      get :search, :address => "CHARBONNET ST"
      assigns(:addresses).should eq([@address])
    end

    it "returns no addresses if none matching are found" do
      get :search, :address => "155 9th St, San Francisco, CA" 
      assigns(:addresses).should eq([])
    end

    it "saves the search terms and user's ip address" do
      get :search, :address => "My house!"
      Search.last.term.should eq "My house!"
      Search.last.ip.should eq "0.0.0.0"
    end
  end

end
