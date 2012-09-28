require 'spec_helper'

describe Case do
  before(:each) do
    @case = FactoryGirl.create(:case)
  end

  it { should have_many(:hearings) }
  it { should have_many(:inspections) }
  it { should have_many(:demolitions) }
  it { should have_one(:judgement) }
  it { should have_one(:case_manager) }
  it { should have_one(:foreclosure) }
  it { should have_many(:resets) }

  it { should validate_uniqueness_of(:case_number) }

  describe "#accela_steps" do
    it "returns all workflow steps associated with a case" do
      @inspection = FactoryGirl.create(:inspection, :case => @case, :inspection_date => Time.now - 1.week)
      @hearing = FactoryGirl.create(:hearing, :case => @case, :hearing_date => Time.now - 1.day)

      steps = @case.accela_steps
      steps.should include(@inspection)
      steps.should include(@hearing)
      steps.length.should eq(2)
    end

    it "returns an empty array if a case has no workflow steps" do
      @case.accela_steps.should eq([])
    end
  end

  describe "#assign_address" do
    it "looks up address by street and house number if they're passed and sets association" do
      @address = FactoryGirl.create(:address)
      @case.assign_address({address_long: "1019 CHARBONNET ST"})

      @case.address.should eq(@address)
    end

    it "looks up address by geopin and assigns it if only one match is found" do
      @address = FactoryGirl.create(:address, :geopin => 12345678)
      @case.update_attribute(:geopin, 12345678)

      @case.assign_address
      @case.address.should eq(@address)
    end

    it "looks up address by geopin and does not assign it if multiple matches are found" do
      @address1 = FactoryGirl.create(:address, :geopin => 12345678)
      @address2 = FactoryGirl.create(:address, :geopin => 12345678, :address_long => "1019-21 CHARBONNET ST", :address_id => "12321443")
      @case.update_attribute(:geopin, 12345678)

      @case.assign_address
      @case.address.should eq(nil)
    end

    it "looks up address by geopin and does not assign it if multiple matches are found" do
      @address1 = FactoryGirl.create(:address, :geopin => 12345678)
      @address2 = FactoryGirl.create(:address, :geopin => 12345678, :address_long => "1019-19 CHARBONNET ST", :address_id => "12321443")
      @address3 = FactoryGirl.create(:address, :geopin => 12345679, :address_long => "1019-19 CHARBONNET ST", :address_id => "12321444")
      
      @case.update_attribute(:geopin, 12345679)
      @case.assign_address(address_long: '1019-19 CHARBONNET ST') 
      
      @case.address.should eq(@address3)
    end
  end

  describe "#most_recent_status" do
    it "returns the most recent workflow step for a case" do
      @inspection = FactoryGirl.create(:inspection, :case => @case, :inspection_date => Time.now - 1.week)
      @hearing = FactoryGirl.create(:hearing, :case => @case, :hearing_date => Time.now - 1.day)

      @case.most_recent_status.should eq(@hearing)
    end
  end

  describe "#first_status" do
    it "returns the first workflow step for a case" do
      @inspection = FactoryGirl.create(:inspection, :case => @case, :inspection_date => Time.now - 1.week)
      @hearing = FactoryGirl.create(:hearing, :case => @case, :hearing_date => Time.now - 1.day)
      
      @case.first_status.should eq(@inspection)
    end
  end

  describe "#elapsed_time" do
    it "returns the elapsed time between first and last step for a case" do
      inspection_date = Time.now - 1.week
      hearing_date = Time.now - 1.day
      FactoryGirl.create(:inspection, :case => @case, :inspection_date => inspection_date)
      FactoryGirl.create(:hearing, :case => @case, :hearing_date => hearing_date)

      @case.elapsed_time.should == (hearing_date.to_datetime.mjd - inspection_date.to_datetime.mjd)
    end
  end

  describe "#complete" do
    it "returns the elapsed time between first and last step for a case" do
      FactoryGirl.create(:inspection, :case => @case)
      FactoryGirl.create(:hearing, :case => @case)
      FactoryGirl.create(:judgement, :case => @case)

      case2 = FactoryGirl.create(:case)
      FactoryGirl.create(:inspection, :case => case2)
      FactoryGirl.create(:hearing, :case => case2)
      FactoryGirl.create(:judgement, :case => case2)

      case3 = FactoryGirl.create(:case)
      FactoryGirl.create(:hearing, :case => case3)
      FactoryGirl.create(:judgement, :case => case3)

      Case.complete.count == 2
    end
  end

  describe "#at_inspection" do
    it "returns # of cases at inspection, should be 0 - /w hearing" do
      FactoryGirl.create(:hearing, :case => @case, :hearing_date => Time.now - 1.day)
      FactoryGirl.create(:judgement, :case => @case)
      result = Case.at_inspection
      result.count.should == 0
    end
  end
  describe "#at_inspection2" do
    it "returns # of cases at inspection, should be 1" do
      result = Case.at_inspection
      result.count.should > 0
    end
  end

  describe "#complete" do
    it "returns # of cases at inspection, should be 1" do

      FactoryGirl.create(:hearing, :case => @case, :hearing_date => Time.now - 1.day)
      FactoryGirl.create(:judgement, :case => @case)
      FactoryGirl.create(:inspection, :case => @case)
      
      case1 = FactoryGirl.create(:case)
      FactoryGirl.create(:judgement, :case => case1)
      FactoryGirl.create(:inspection, :case => case1)
      
      case2 = FactoryGirl.create(:case)
      FactoryGirl.create(:hearing, :case => case2, :hearing_date => Time.now - 1.day)
      FactoryGirl.create(:inspection, :case => case2)
      
      case3 = FactoryGirl.create(:case)
      FactoryGirl.create(:hearing, :case => case3, :hearing_date => Time.now - 1.day)
      FactoryGirl.create(:judgement, :case => case3)
      

      result = Case.complete
      result.count.should == 1
    end
  end

  describe "#hearings without judgement" do
    it "returns # of cases at inspection, should be 1" do

      FactoryGirl.create(:hearing, :case => @case, :hearing_date => Time.now - 1.day)
      FactoryGirl.create(:judgement, :case => @case)
      
      case2 = FactoryGirl.create(:case)
      FactoryGirl.create(:hearing, :case => case2, :hearing_date => Time.now - 1.day)
      FactoryGirl.create(:inspection, :case => case2)
      
      case3 = FactoryGirl.create(:case)
      FactoryGirl.create(:hearing, :case => case3)

      result = Case.hearings_without_judgement
      result.count.should == 2
    end
  end
  describe "#without_inspection" do
    it "returns # of cases without an inspection, should be 1" do

      case2 = FactoryGirl.create(:case)
      FactoryGirl.create(:hearing, :case => case2, :hearing_date => Time.now - 1.day)
      FactoryGirl.create(:inspection, :case => case2)
      
      result = Case.without_inspection
      result.count.should == 1
    end
  end
  describe "#matched_count" do
    it "returns # of cases matched" do
      @case.address = FactoryGirl.create(:address)
      @case.save
      FactoryGirl.create(:case)
      
      result = Case.matched_count
      result.should == 1
    end
  end
  describe "#unmatched_count" do
    it "returns # of cases unmatched" do
      @case.address = FactoryGirl.create(:address)
      @case.save
      FactoryGirl.create(:case)
      FactoryGirl.create(:case)

      result = Case.unmatched_count
      result.should == 2
    end
  end
  describe "#pct_matched" do
    it "returns pct of matched cases" do

      @address = FactoryGirl.create(:address)

      FactoryGirl.create(:case, :address => @address)
      FactoryGirl.create(:case, :address => @address)
      FactoryGirl.create(:case, :address => @address)

      result = Case.pct_matched
      result.should == 75.0
    end
  end
end
