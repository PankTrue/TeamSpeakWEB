class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :admin?

  def home
    @users = User.all
    @count_users = @users.count
    @count_spent=0
    @users.each do |u|
      @count_spent+=u.spent
    end
  end

  def info
    @user = User.where(id: params[:id]).take!
  end

  def belongs_verification
    server = Teamspeak::Functions.new
    physical_servers = server.server_list
    logic_servers = Tsserver.all
    @physical = machine_id_list_not_found_in_db physical_servers, logic_servers
    @logic = machine_id_list_not_found_on_physical_server physical_servers, logic_servers
    server.disconnect
  end

  def user_list
    @users = User.all
    @server =Tsserver.all
  end

  def setmoney
    @user = User.where(id: params[:id]).first
    @user.update money: params[:money]
    respond_to do |format|
      format.html { redirect_to admin_info_path @user.id  }
    end
  end

  def servers
    server = Teamspeak::Functions.new
    @ts = Tsserver.all
    @physical = server.server_list
    server.disconnect
  end

  def del_physical_server
    server=Teamspeak::Functions.new
    server.server_destroy(params[:id])
    redirect_to admin_servers_path
  end

  def amounts
    @amounts = Payment.all
  end

private
  def admin?
    unless Settings.other.admin_list.include?(current_user.email)
      redirect_to root_path
    end
  end

  def machine_id_list_not_found_in_db physical, logic
    arr_no_physical = Array.new
    physical.each do |p|
      status = true
      logic.each do |l|
        if p["virtualserver_id"]==l.machine_id
          status = false
          break
        end
      end
      arr_no_physical << p if status
    end
    return arr_no_physical
  end

  def machine_id_list_not_found_on_physical_server physical, logic
    arr_no_logic = Array.new
    logic.each do |l|
      status = true
      physical.each do |p|
        if p["virtualserver_id"]==l.machine_id
          status = false
          break
        end
      end
      arr_no_logic << l if status
    end
    return arr_no_logic
  end

end
