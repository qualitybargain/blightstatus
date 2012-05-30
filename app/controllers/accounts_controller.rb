class AccountsController < ApplicationController
  before_filter :authenticate_account!

  def index
    street_name = AddressHelpers.get_street_name('Van Ave')
    @my_addresses = Address.find_addresses_with_cases_by_street(street_name).page(params[:page]).order(:house_num)
  end
  
  def show
  end

  def edit
  end
  
end