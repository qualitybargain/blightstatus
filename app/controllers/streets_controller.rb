
class StreetsController < ApplicationController
  respond_to :html, :json, :xml	
  autocomplete :street, :full_name

  def autocomplete_street_full_name
    term = AddressHelpers.abbreviate_street_direction(params[:term])
    if term && !term.empty?
        items = Street.select("DISTINCT full_name").
            where("LOWER(full_name) LIKE ?", term.downcase + '%').
            limit(10).order(:full_name)        
     else
       items = {}
     end
     render :json => json_for_autocomplete(items, :full_name)
  end
  
end
