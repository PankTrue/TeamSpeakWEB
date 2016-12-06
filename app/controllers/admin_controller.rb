class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :admin?

  def home
    @users = User.all
  end

  def info
    @user = User.where(id: params[:id]).take!
  end

  def setmoney
    @user = User.where(id: params[:id]).take!
    @user.update money: params[:money]
    @user.save
    respond_to do |format|
      format.html { redirect_to admin_info_path @user.id  }
    end
  end

private
  def admin?
    unless Settings.other.admin_list.include?(current_user.email)
      redirect_to root_path
    end
  end

end
