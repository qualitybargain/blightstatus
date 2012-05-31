class SubscriptionsController < ApplicationController
  respond_to :html, :json, :xml
  
  def create
    account = current_account
    
    
    @sub = Subscription.new({:address_id => params[:id], :account_id => account.id})
    
    #@sub = Subscription.new({:address_id => 70086, :account_id => 1})
    if @sub.save
      #success
      respond_with @sub
    else
      #not sucess
      respond_with :errors => @sub.errors 
    end
  end
end
