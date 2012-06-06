class StatisticsController < ApplicationController

  respond_to :html, :json, :xml	
  
  def index
  	# stat = Statistic.new
  	# @caseStats = stat.Cases
  	# @addrStats = stat.Addresses
  	# @inspStats = stat.Inspections
  	# @notiStats = stat.Notifications
  	# @hearStats = stat.Hearings
  	# @judgeStats = stat.Judgements
  	# @resetStats = stat.Resets
  	# @demoStats = stat.Demolitions
  	# @maintStats = stat.Maintenances
  	# @foreclStats = stat.Foreclosures
  	# respond_with({:cases => @caseStats, :addresses => @addrStats, :inspections => @inspStats, :notifications => @notiStats, :hearings => @hearStats, :judgements => @judgeStats, :resets => @resets, :maintenances => @maintStats, :foreclosures => @foreclStats, :demolitions => @demoStats})
  end

  def graphs
    # stat = Statistic.new
    # @caseStats = stat.Cases
    # @addrStats = stat.Addresses
    # @inspStats = stat.Inspections
    # @notiStats = stat.Notifications
    # @hearStats = stat.Hearings
    # @judgeStats = stat.Judgements
    # @resetStats = stat.Resets
    # @demoStats = stat.Demolitions
    # @maintStats = stat.Maintenances
    # @foreclStats = stat.Foreclosures
    # respond_with({:cases => @caseStats, :addresses => @addrStats, :inspections => @inspStats, :notifications => @notiStats, :hearings => @hearStats, :judgements => @judgeStats, :resets => @resets, :maintenances => @maintStats, :foreclosures => @foreclStats, :demolitions => @demoStats})
  end
end
