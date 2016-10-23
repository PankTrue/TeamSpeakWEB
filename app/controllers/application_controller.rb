class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  def current_ts
    if !session[:ts_id].nil?
      Tsserver.find(session[:ts_id])
    else
      Tsserver.new
    end
  end
end
