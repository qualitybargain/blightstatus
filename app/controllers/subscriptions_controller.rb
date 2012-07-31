class SubscriptionsController < ApplicationController
  respond_to :html, :json, :xml
  
  def create
    account = current_account
    points = Array.new
    factory = RGeo::Cartesian.factory

    params[:polygon].each{|index, item|
      puts item.inspect
      points.push(factory.point( item['lng'].to_f, item['lat'].to_f ))
    }
    #close the polygon with the first position
    # points << factory.point( params[:polygon].first.['lng'].to_f, params[:polygon].first.['lat'].to_f )

    polygon = factory.polygon(factory.linear_ring(points))
    # puts polygon.inspect

    #TODO: you have to manually remove the 
    @sub = Subscription.create({:address_id => params[:id], :account_id => account.id, :thegeom => polygon})

    if @sub.save
      respond_with @sub
    else
      respond_with :errors => @sub.errors 
    end
  end


  def send_notifications
    users = Subscription.find(:all).group("account_id")
    
    # Get all the subscribers
    users.each{ | user, item | 

      subscriptions = Subscription.find_by_user_id(user.account_id)

      SubscriptionMailer.notify(@user).deliver

    }

  end

  
end