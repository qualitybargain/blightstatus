class SubscriptionsController < ApplicationController
  respond_to :html, :json, :xml
  
  def create
    account = current_account
    
    #@sub = Subscription.find_or_create_by_address_id_and_account_id({:address_id => params[:id], :account_id => account.id})

    @sub = Subscription.new({:address_id => params[:id], :account_id => account.id})
    
    if @sub.save
      #success
      respond_with @sub
    else
      #not success
      respond_with :errors => @sub.errors 
    end
  end
end
