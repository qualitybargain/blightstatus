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

  describe "GET show" do
    it "assigns the request address as @address" do
      get :show, :id => @address.id
      assigns(:address).should eq(@address)
    end
  end

  describe "GET search" do
    context "matching full address" do
      it "redirects to show page for address" do
        get :search, :address => "1019 CHARBONNET ST"
        response.should redirect_to(address_path(@address))
      end
    end

    context "matching neighborhood" do
      before :each do
        neighborhood = FactoryGirl.create(:neighborhood, :name => "MID CITY")
        @address.neighborhood = neighborhood
        @address.cases << FactoryGirl.create(:case)
        @address.save
      end

      it "returns all properties within a given neighborhood with cases" do
        get :search, :address => "MID CITY"
        assigns(:addresses).should eq([@address])
      end

      it "normalizes for capitalization" do
        get :search, :address => "MiD CiTy"
        assigns(:addresses).should eq([@address])
      end
    end

    context "matching street name without house number" do
      it "returns all properties on that street with a case" do
        FactoryGirl.create(:case, :address => @address)

        get :search, :address => "CHARBONNET ST"
        assigns(:addresses).should eq([@address])
      end
    end

    context "no matching address" do
      it "returns an empty array" do
        get :search, :address => "155 9th St, San Francisco, CA" 
        assigns(:addresses).should eq([])
      end
    end

    it "saves the search terms and user's ip address" do
      get :search, :address => "My house!"
      Search.last.term.should eq "My house!"
      Search.last.ip.should eq "0.0.0.0"
    end
  end

  describe "GET addresses_with_case" do
    it "returns a json of addresses with inspections in the last 2 weeks" do
      get :addresses_with_case, :format => :json, :type => "inspections"
      response.should be_success
    end
  end

  describe "GET map_search" do
  end

  describe "GET redirect_latlong" do
  end

end
