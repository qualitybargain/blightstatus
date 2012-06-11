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
    @address = Address.find(params[:id])

    respond_with(@address)
  end

  def search
    @search_term = params[:address]
    Search.create(:term => @search_term, :ip => request.remote_ip)
    address_result = AddressHelpers.find_address(params[:address])

    # When user searches they get a direct hit!
    if address_result.length == 1
      redirect_to :action => "show", :id => address_result.first.id
      # TODO: if json, then we should not redirect.
      # This shouldn't be hard to do - just check if it's an xhr request with request.xhr?
    else
      street_name = AddressHelpers.get_street_name(@search_term)

      @addresses = Address.find_addresses_with_cases_by_street(street_name).uniq.order(:house_num).page(params[:page]).per(15)

      @addresses.each {|addr| 
        addr.address_long = AddressHelpers.unabbreviate_street_types(addr.address_long).capitalize
      }

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @addresses }
        format.json { render :json => @addresses.to_json(:methods => [:most_recent_status_preview]) }
      end
    end
  end

  def map_search
    ne = params["northEast"]
    sw = params["southWest"]

    @addresses = Address.find_addresses_within_area(ne, sw)

    page = (params[:page] || 1).to_i
    offset = (page - 1) * 15
    page_count = @addresses.count / 15
    @addresses = @addresses.slice(offset, 15)

    respond_with [@addresses.to_json(:methods => [:most_recent_status_preview]), :page_count => page_count, :page => page]
  end
end
