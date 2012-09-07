class StatisticsController < ApplicationController

  respond_to :html, :json

  def graphs
  end

  def maps
	@date = Time.now()
  end

end