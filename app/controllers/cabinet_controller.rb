class CabinetController < ApplicationController
include CabinetHelper
require 'date'
	before_action :authenticate_user!
	before_action :ts_params, only: [:create]


  def home
    @ip = 'localhost'
    @user=current_user

    # server=CabinetHelper::Server.new
   # @data=server.serverlist
   @status = CabinetHelper::Server.new

  end

  def new
    @user=current_user
    @ts=Tsserver.new
  end

def create
  server=CabinetHelper::Server.new
  if server.server_worked?
    user = current_user
    @ts = Tsserver.new(ts_params)

    time = ts_params[:time_payment].to_i
    @ts.time_payment = time
    @ts.user_id = user.id

    cost = time * 3 * @ts.slots
    if @ts.dns == ""
      @ts.dns = nil
    end

      if user.money >= cost
        if @ts.valid?
          @ts.time_payment = time_pay(time)
          data=server.server_create(free_port,@ts.slots)
          @ts.machine_id=data['sid']
          @ts.port =data['virtualserver_port']
          @token=data['token']
          @ts.save validate: false
            flash[:notice] = "Ваш ключ: #{@token}"
            redirect_to cabinet_home_path
          user.money = user.money - cost
          user.save
        else
           render cabinet_new_path
        end
      else
        flash[:notice]='Недостаточно средств'
        redirect_to cabinet_home_path
      end
  else
      flash[:notice] = 'В данный момент сервер не работает. Повторите попытку позже'
      redirect_to cabinet_home_path
  end

end



def destroy
  server=CabinetHelper::Server.new
  if server.server_worked?
    if @ts = Tsserver.where(id: params[:id]).first
      if @ts.user_id == current_user.id
        server.server_destroy(@ts.machine_id)
        @ts.destroy
        redirect_to cabinet_home_path
      else
        redirect_to cabinet_home_path
      end
    else
      redirect_to cabinet_home_path
    end
  else
    flash[:notice] = 'Невозможно удалить сервер, т.к. он выключен.'
    redirect_to cabinet_home_path
  end
end

def extend
  @ts = Tsserver.new
  @servers = Tsserver.where(user_id: current_user.id)
end

def extend_up
  ts = Tsserver.new(extend_params)
  s = Tsserver.where(id: ts.id)
  user = current_user
if user.money >= (s.slots * 3)
  if user.id == s.user_id
    user.money = user.money - (s.slots * 3)
    s.time_payment = s.time_payment >> (ts.time_patment).to_i
    s.save
    user.save
  else
    redirect_to cabinet_home_path
  end
else
  flash[:notice] = 'Недостаточно средств'
  redirect_to cabinet_home_path
end
end


private

  def time_pay(time)
    date = Time.now
    date = date.to_date
    return date >> time.to_i
  end


	def ts_params
		params.require(:tsserver).permit(:slots, :dns, :time_payment)
  end

  def extend_params
    params.require(:tsserver).permit(:time_payment, :id)
  end



  def free_port
    i=2000
    server=CabinetHelper::Server.new
    data=server.serverlist
    used_ports=[]
      data.each do |temp|
        used_ports << temp['virtualserver_port']
      end

    while true
      if used_ports.include?(i)
        i+=1
        next
      end
      ts = %x'lsof -i :#{i}'
      if ts.empty?
        return i
      else
        i+=1
      end
    end
  end


end
