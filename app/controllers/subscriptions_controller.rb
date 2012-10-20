class SubscriptionsController < ApplicationController
  respond_to :html, :json
  # before_filter :authenticate_account!

  def update
    account = current_account
    # points = Array.new
    # factory = RGeo::Cartesian.factory

    # params[:polygon].each{|index, item|
    #   puts item.inspect
    #   points.push(factory.point( item['lng'].to_f, item['lat'].to_f ))
    # }

    # polygon = factory.polygon(factory.linear_ring(points))

    @subscription = Subscription.find_or_create_by_address_id_and_account_id({:address_id => params[:id], :account_id => account.id, :date_notified => Time.now })


    if @subscription.save
      respond_to do |format|
        format.html
        format.json { render :json => @subscription.to_json }
      end
    end
  end


  def destroy
    account = current_account

    @subscription = Subscription.destroy_all({:address_id => params[:id], :account_id => account.id})

    if @subscription
      respond_to do |format|
        format.html
        format.json { render :json => @subscription.to_json }
      end
    end
  end
  
end
