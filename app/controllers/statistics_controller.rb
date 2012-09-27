class StatisticsController < ApplicationController

  respond_to :html, :json

  def browse
    @date = Time.now()
  end

  def stats
  end

end
