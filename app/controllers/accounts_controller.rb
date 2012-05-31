class AccountsController < ApplicationController
  before_filter :authenticate_account!
  respond_to :html, :json, :xml

  def index    
    user = current_account
    @account_subcriptions = user.addresses
  end
  
  def show
  end

  def edit
  end
  
end