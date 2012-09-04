require 'rgeo/cartesian/bounding_box'
require "#{Rails.root}/lib/address_helpers.rb"
include AddressHelpers

class AddressesController < ApplicationController
  respond_to :html, :xml, :json

  # we are not using  :full => true  because we want to show only street names or addresses. not mix 'em
  autocomplete :address, :address_long

  def index
    @addresses = Address.page(params[:page]).order(:address_long)

    respond_with(@addresses)
  end

  def show
    if account_signed_in?
      @account = current_account
      @account_subscribed = !@account.subscriptions.where(:address_id => params[:id]).empty? 
    end
    @address = Address.find(params[:id])

    # if APP_CONFIG['demo_page_id'] == @address.id
    #   render :action => 'show-demo'  
    # else
      respond_with(@address, @account_subscribed)
    # end
  end


  def search
    @search_term = params[:address]
    Search.create(:term => @search_term, :ip => request.remote_ip)
    address_result = AddressHelpers.find_address(params[:address])

    # When user searches they get a direct hit!
    if address_result.length == 1
      redirect_to :action => "show", :id => address_result.first.id
    else
      street_name = AddressHelpers.get_street_name(@search_term)

      if(dir = AddressHelpers.get_direction(@search_term))
        @addresses = Address.find_addresses_with_cases_by_cardinal_street(dir,street_name).uniq.order(:house_num).page(params[:page]).per(10)
      else
        @addresses = Address.find_addresses_with_cases_by_street(street_name).uniq.order(:street_name, :house_num).page(params[:page]).per(10)
      end

      @addresses.each {|addr|
        addr.address_long = AddressHelpers.unabbreviate_street_types(addr.address_long).capitalize
      }
      @address_list = @addresses.sort{ |a, b| a.house_num.to_i <=> b.house_num.to_i }
      
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @addresses_list }
        format.json { render :json => @address_list.to_json(:methods => [:most_recent_status_preview]) }
      end
    end
  end

  def map_search
    ne = params["northEast"]
    sw = params["southWest"]
    @addresses = Address.find_addresses_with_cases_within_area(ne, sw)

    page = (params[:page] || 1).to_i
    offset = (page - 1) * 10
    page_count = @addresses.count / 10
    @addresses = @addresses.slice(offset, 10)

    respond_with [@addresses.to_json(:methods => [:most_recent_status_preview]), :page_count => page_count, :page => page]
  end


  def addresses_with_case

    date = Time.now


    params[:start_date] = params[:start_date].nil? ? (date - 2.weeks).to_s : params[:start_date]
    params[:end_date] = params[:end_date].nil? ? (date).to_s : params[:end_date]

    start_date = Date.parse(params[:start_date]).strftime('%Y-%m-%d')
    end_date = Date.parse(params[:end_date]).strftime('%Y-%m-%d')

    # TODO: we should be returning GeoJSON instead. This is how:
    # RGeo::ActiveRecord::GeometryMixin.set_json_generator(:geojson)
    # @cases = ''
    case params[:type]
      when 'inspections'
        @cases = Address.joins(:inspections).where(" inspection_date > '#{start_date}' AND inspection_date < '#{end_date}' ").pluck(:point)
      when 'hearings'
        @cases = Address.joins(:hearings).where(" hearing_date > '#{start_date}' AND hearing_date < '#{end_date}' ").pluck(:point)
      when 'judgements'
        @cases = Address.joins(:judgements).where(" judgement_date > '#{start_date}' AND judgement_date < '#{end_date}' ").pluck(:point)
      when 'demolitions'
        @cases = Address.joins(:demolitions).where(" date_completed > '#{start_date}'  AND date_completed < '#{end_date}' ").pluck(:point)
    end

    respond_to do |format|
      format.json { render :json => @cases.to_json }
    end
      
  end

end
