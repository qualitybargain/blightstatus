class AccountsController < ApplicationController
  before_filter :authenticate_account!
  respond_to :html, :json

  def index
    @account = current_account
    @account_subcriptions = @account.addresses

    respond_to do |format|
      format.html
      format.json { render :json => @account_subcriptions.to_json }
    end
  end

  def map
    @account = current_account
    @polygon_subcriptions = Subscription.where(:account_id => @account.id)

    polygon = Subscription.last.thegeom
    geojson = RGeo::GeoJSON::encode(polygon)

    respond_to do |format|
      format.html
      format.json { render :json => geojson.to_json }
    end
  end

  def notify
    @account = current_account
    if @account.update_attributes(params[:account])
      render :json => {:saved => true}
    else
      render :json => {:saved => false}
    end
  end

  def show

  end

  def edit
  end
  
end
