class CasesController < ApplicationController
  respond_to :html, :json

  def index

    case params[:type]
      when 'inspections'
        @cases = Address.joins(:inspections).where(" inspection_date > '2012-01-01 11:00:00' AND inspection_date < '2012-01-29 11:00:00' ").pluck(:point)
      when 'hearings'
        @cases = Address.joins(:hearings).where(" hearing_date > '2012-01-01 11:00:00' AND hearing_date < '2012-01-29 11:00:00' ").pluck(:point)
      when 'judgements'
        @cases = Address.joins(:judgements).where(" judgement_date > '2012-01-01 11:00:00' AND judgement_date < '2012-01-29 11:00:00' ").pluck(:point)
      when 'demolitions'
        @cases = Address.joins(:demolitions).where(" date_completed > '2012-01-01 11:00:00' AND date_completed < '2012-01-29 11:00:00' ").pluck(:point)
      else
        @cases = Case.page(params[:page])
    end


    polygon = Subscription.last.thegeom
    geojson = RGeo::GeoJSON::encode(polygon)


    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @cases.to_json }
    end
      
  end

  def show
    @case = Case.find(params[:id])
    respond_with(@case)
  end
end
