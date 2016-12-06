module ApplicationHelper

  def admin?
    if Settings.other.admin_list.include?(current_user.email)
      return true
    else
      return false
    end
  end
end
