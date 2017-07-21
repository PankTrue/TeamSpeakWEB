class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:vk_callback]

  def index
  end

  def news
  end

  def ref
    cookies[:ref]={value: params[:ref], expires: 1.month.from_now,} if params[:ref] and params[:ref].to_i!=0 and current_user.blank?
    redirect_to root_path
  end

  def how_buy
  end


end
