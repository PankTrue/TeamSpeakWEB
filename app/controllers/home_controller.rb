class HomeController < ApplicationController
  def index
  end

  def news
  end

  def ref
    cookies[:ref]={value: params[:ref], expires: 1.month.from_now,} if params[:ref] and params[:ref].to_i!=0 and current_user.blank?
    redirect_to root_path
  end

  def write_email

  end

  def vk_callback
    respond_to do |format|
      format.text {render text: '4eccf9b9'}
    end
  end

end
