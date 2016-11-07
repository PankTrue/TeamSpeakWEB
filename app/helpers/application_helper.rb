module ApplicationHelper

  def admin?
    if Rails.application.secrets.admin_list.include?(current_user.email)
      return true
    else
      return false
    end
  end
end
