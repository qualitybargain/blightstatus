require 'date'

class CasesController < ApplicationController
  respond_to :html, :json

  def index

    @cases = Case.page(params[:page])

    #respond_with(@cases)
    respond_to do |format|
        format.html
        format.json { render :json => @cases}
    end  
  end

  def show
    @case = Case.find(params[:id])
    #respond_with(@case)
    respond_to do |format|
        format.html
        format.json { render :json => @case}
    end
  end
end
