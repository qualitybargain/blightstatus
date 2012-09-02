require 'date'

class CasesController < ApplicationController
  respond_to :html, :json

  def index


    start_date = Date.parse(params[:start_date]).strftime('%Y-%m-%d')
    end_date = Date.parse(params[:end_date]).strftime('%Y-%m-%d')


    case params[:type]
      when 'inspections'
        @cases = Address.joins(:inspections).where(" inspection_date > '#{start_date}' AND inspection_date < '#{end_date}' ").pluck(:point)
      when 'hearings'
        @cases = Address.joins(:hearings).where(" hearing_date > '#{start_date}' AND hearing_date < '#{end_date}' ").pluck(:point)
      when 'judgements'
        @cases = Address.joins(:judgements).where(" judgement_date > '#{start_date}' AND judgement_date < '#{end_date}' ").pluck(:point)
      when 'demolitions'
        @cases = Address.joins(:demolitions).where(" date_completed > '#{start_date}'  AND date_completed < '#{end_date}' ").pluck(:point)
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
