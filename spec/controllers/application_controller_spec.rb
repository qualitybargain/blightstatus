require 'spec_helper'

describe ApplicationController do
  controller do
    respond_to :html, :json, :xml

    def create
      @account = FactoryGirl.build_stubbed(:account)
      redirect_to after_sign_in_path_for(@account)
    end
  end

  describe "#after_sign_in_path_for" do
    context "sign in page" do
      it "goes to the default Devise sign in path" do
        #TODO figure out how to set request.referrer
        # get :create, :referer => "http://test.host/admins/sign_in"
        # response.should redirect_to(accounts_path)
      end
    end

    context "from any other page" do
      context "stored location set" do
        it "redirects to the stored location" do
          session[:"account_return_to"] = "/foo.bar"
          get :create
          response.should redirect_to("/foo.bar")
        end
      end

      context "no stored location set" do
        it "redirects to the root path" do
          get :create
          response.should redirect_to(root_path)
        end
      end
    end
  end
end
