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
      #respond_with(@address, @account_subscribed)
    # end
    respond_to do |format|
        format.html
        format.json { render :json => {:address => @address, :account => @account}}
      end
  end


  def search
    RGeo::ActiveRecord::GeometryMixin.set_json_generator(:geojson)

    @search_term = params[:address]
    Search.create(:term => @search_term, :ip => request.remote_ip)

    address_result = AddressHelpers.find_address(params[:address])

    # When user searches they get a direct hit!
    if address_result.length == 1
      redirect_to :action => "show", :id => address_result.first.id
    else
      if Neighborhood.exists?(:name => @search_term)
        @addresses = Address.find_addresses_with_cases_by_neighborhood(@search_term)
      else
        street_name = AddressHelpers.get_street_name(@search_term)

        if(dir = AddressHelpers.get_direction(@search_term))
          @addresses = Address.find_addresses_with_cases_by_cardinal_street(dir,street_name).uniq.order(:house_num) 
        else
          @addresses = Address.find_addresses_with_cases_by_street(street_name).uniq.order(:street_name, :house_num)
        end
      end

      @addresses.each {|addr|
        addr.address_long = AddressHelpers.unabbreviate_street_types(addr.address_long).capitalize
      }
      @address_list = @addresses.sort{ |a, b| a.house_num.to_i <=> b.house_num.to_i }
      
      respond_to do |format|
        format.html
        format.json { render :json => @address_list.to_json(:only => [ :id, :address_long, :latest_type, :point ]) }
      end
    end
  end


  def addresses_with_case
    RGeo::ActiveRecord::GeometryMixin.set_json_generator(:geojson)
    date = Time.now

    params[:start_date] = params[:start_date].nil? ? (date - 1.month).to_s : params[:start_date]

    start = Date.parse(params[:start_date])

    start_date = start.strftime('%Y-%m-%d')
    end_date = start + 1.month - 1.day
    class_name = ''



    append_sql_query = ''
    sql_params = {:start_date => start_date, :end_date => end_date} 

    if params[:only_recent_status].to_i == 1
      append_sql_query = " AND cases.status_type = :status_type "
      case params[:status]
        when 'inspections'
          sql_params[:status_type] = "Inspection"
        when 'notifications'
          sql_params[:status_type] = "Notification"
        when 'hearings'
          sql_params[:status_type] = "Hearing"
        when 'judgements'
          sql_params[:status_type] = "Judgement"
        when 'foreclosures'
          sql_params[:status_type] = "Foreclosure"
        when 'demolitions'
          sql_params[:status_type] = "Demolition"
        when 'abatement'
          sql_params[:status_type] = "Maintenance"
      end
    end


    case params[:status]
      when 'inspections'
        cases = Case.includes(:address, :inspections).where(" cases.address_id = addresses.id  AND inspections.inspection_date > :start_date AND inspections.inspection_date < :end_date #{append_sql_query} ",  sql_params)
      when 'notifications'
        cases = Case.includes(:address, :notifications).where(" cases.address_id = addresses.id  AND notified > :start_date  AND notified < :end_date #{append_sql_query}",   sql_params)
      when 'hearings'
        cases = Case.includes(:address, :hearings).where(" cases.address_id = addresses.id  AND  hearing_date > :start_date  AND hearing_date < :end_date #{append_sql_query}",   sql_params )
      when 'judgements'
        cases = Case.includes(:address, :judgements).where(" cases.address_id = addresses.id  AND  judgement_date > :start_date  AND judgement_date < :end_date #{append_sql_query}", sql_params )
      when 'foreclosures'
        cases = Case.includes(:address, :foreclosures).where(" cases.address_id = addresses.id  AND  sale_date > :start_date   AND sale_date < :end_date #{append_sql_query}",  sql_params )
      when 'demolitions'
        cases = Case.includes(:address, :demolitions).where(" cases.address_id = addresses.id  AND  date_completed > :start_date  AND date_completed <  :end_date  #{append_sql_query}" ,  sql_params )
      when 'abatement'
        cases = Case.includes(:address, :maintenances).where(" cases.address_id = addresses.id  AND  date_completed > :start_date   AND date_completed < :end_date  #{append_sql_query}",   sql_params)
    end


    # TODO: performance needs to be evaluated! compact!, compact, delete, reject etc
    if cases.nil?
      cases = Hash.new
    end

    case_addresses = cases.map{| single_case |
      single_case.address
    }




    respond_to do |format|
      # format.json { render :json =>  {:cases => case_addresses, :stats => stats}.to_json }
        format.json { render :json => case_addresses.to_json(:only => [ :id, :address_long, :latest_type, :point ]) }      
    end
      
  end



  def map_search
    ne = params["northEast"]
    sw = params["southWest"]
    @addresses = Address.find_addresses_with_cases_within_area(ne, sw)

    # respond_with [@addresses.to_json(:methods => [:most_recent_status_preview])]

    respond_to do |format|
        format.json { render :json => @addresses.to_json }
    end    
  end


  def redirect_latlong
    # factory = RGeo::Cartesian.factory
    # location = factory.point(params[:x].to_f, params[:y].to_f)
    @address = Address.where(" point = ST_GeomFromText('POINT(#{params[:x].to_f} #{params[:y].to_f})') " ).first
    redirect_to address_url(@address), :status => :found
  end


  private

  # DEPRCATED
  def get_stats(status, sql_params)
    puts '-----------GET STATS-----------------'
    puts status.inspect
    puts sql_params.inspect
    case status
      when "inspections"
        Inspection.where(" inspections.inspection_date > :start_date AND inspections.inspection_date < :end_date ",  sql_params).results
      when "notifications"
        Notification.where(" notified > :start_date  AND notified < :end_date ",   sql_params).types
      when "hearings"
        Hearing.where(" hearing_date > :start_date  AND hearing_date < :end_date ",   sql_params ).status
      when "judgements"
        Judgement.where(" judgement_date > :start_date  AND judgement_date < :end_date ", sql_params ).status
      when "maintenances"
        Maintenance.where(" date_completed > :start_date   AND date_completed < :end_date ",  sql_params ).status
      when "foreclosures"
        Foreclosure.where(" sale_date > :start_date  AND sale_date <  :end_date  " ,  sql_params ).status
      when "demolitions"
        Demolition.where(" date_completed > :start_date   AND date_completed < :end_date  ",   sql_params).status
    end
  end

end
