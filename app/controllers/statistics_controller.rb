class StatisticsController < ApplicationController

  respond_to :html, :json


  def browse
		@date = Time.now()
  end

  def stats

  	start_date = params[:start_date]
  	end_date = params[:end_date]
  	case params[:type]

			when "addresses"
				@response = {
											:result => Address.count 
										}

			when "cases"
				@response = { 
											:result => Case.count, 
										}

			when "inspections"
				@response = { 
											:result => Inspection.where(" inspection_date > '#{start_date}' AND inspection_date < '#{end_date}' ").results
										}

			when "notifications"
				@response = { 
											:result => Notification.where(" notification_date > '#{start_date}' AND notification_date < '#{end_date}' ").results
										}

			when "hearings"
				@response = { 
											:result => Hearing.where(" hearing_date > '#{start_date}' AND hearing_date < '#{end_date}' ").status
										}

			when "resets"
				@response = { 
											:result => Reset.where(" reset_date > '#{start_date}' AND reset_date < '#{end_date}' ").status
										}

			when "judgements"
				@response = { 
											:result => Judgement.where(" judgement_date > '#{start_date}' AND judgement_date < '#{end_date}' ").status
										}

			when "maintenances"
				@response = { 
											:result => Maintenance.where(" maintenance_date > '#{start_date}' AND maintenance_date < '#{end_date}' ").status
										}

			when "foreclosures"
				@response = { 
											:result => Foreclosure.where(" foreclosure_date > '#{start_date}' AND foreclosure_date < '#{end_date}' ").status
										}

			when "demolitions"
				@response = { 
											:result => Demolition.where(" demolition_date > '#{start_date}' AND demolition_date < '#{end_date}' ").status
										}
		end

    respond_to do |format|
      format.json { render :json => @response.to_json }
    end
  end

end