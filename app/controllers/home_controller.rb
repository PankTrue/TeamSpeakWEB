class HomeController < ApplicationController
  def index
  end

  def about
  end

  def ref
    cookies[:ref]={value: params[:ref], expires: 1.month.from_now,} if params[:ref] and cookies[:ref].blank? and current_user.blank?
    redirect_to root_path
  end
end
