class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  add_flash_types :success, :danger, :info, :warning


  def referall_system cost, user_id #maybe set in private
    if user_id != 0
      u = User.find user_id
      u.add_money((cost*0.1).round(2))
    end
  end



end
