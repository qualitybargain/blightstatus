class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :handle_cookies

  def after_sign_in_path_for(resource)                                                                                                                      
    sign_in_url = url_for(:action => 'new', :controller => 'sessions', :only_path => false, :protocol => 'http')                                            
    if (request.referer == sign_in_url)      
      super                                                                                                                                                 
    else
      stored_location_for(resource) || root_path                                                                                         
    end                                                                                                                                                     
  end
  
  private
    def handle_cookies
      @agree_to_legal_disclaimer = !cookies[:agree_to_legal_disclaimer].nil?
    end


end

