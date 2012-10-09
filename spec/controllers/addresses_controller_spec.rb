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
    let(:kase){ FactoryGirl.create(:case, :address => @address) }

    context "inspections" do
      it "returns inspections from the last month in JSON format" do
        kase.inspections << FactoryGirl.create(:inspection)

        get :addresses_with_case, :format => :json, :type => "inspections"
        response.should be_success
      end
    end

    context "notifications" do
      it "returns notifications from the last month in JSON format" do
        kase.notifications << FactoryGirl.create(:notification)

        get :addresses_with_case, :format => :json, :type => "notifications"
        response.should be_success
      end
    end

    context "hearings" do
      it "returns hearings from the last month in JSON format" do
        kase.hearings << FactoryGirl.create(:hearing)

        get :addresses_with_case, :format => :json, :type => "hearings"
        response.should be_success
      end
    end

    context "judgments" do
      it "returns judements from the last month in JSON format" do
        kase.judgement = FactoryGirl.create(:judgement)

        get :addresses_with_case, :format => :json, :type => "judements"
        response.should be_success
      end
    end

    context "foreclosures" do
      it "returns foreclosures from the last month in JSON format" do
        kase.foreclosure = FactoryGirl.create(:foreclosure)

        get :addresses_with_case, :format => :json, :type => "foreclosures"
        response.should be_success
      end
    end

    context "demolitions" do
      it "returns demolitions from the last month in JSON format" do
        kase.demolitions << FactoryGirl.create(:demolition)

        get :addresses_with_case, :format => :json, :type => "demolitions"
        response.should be_success
      end
    end

    context "maintenances" do
      it "returns maintenances from the last month in JSON format" do
        kase.maintenances << FactoryGirl.create(:maintenance)

        get :addresses_with_case, :format => :json, :type => "maintenances"
        response.should be_success
      end
    end
  end

  describe "GET map_search" do
  end

  describe "GET redirect_latlong" do
  end

end
