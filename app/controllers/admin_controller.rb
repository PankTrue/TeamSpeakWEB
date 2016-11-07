class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :admin?
  def home
  end


private
  def admin?
    unless Rails.application.secrets.admin_list.include?(current_user.email)
      redirect_to root_path
    end
  end

end
