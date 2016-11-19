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
   @servers = Tsserver.where(user_id: current_user.id)

end

def edit
  @ts = Tsserver.new
  @s = Tsserver.where(id: params[:id]).take!
  @days = sec2days(@s.time_payment.to_time - Time.now)
end

def update
  ts = Tsserver.where(id: params[:id]).take!
  user = User.where(id: current_user.id).take!
  server = CabinetHelper::Server.new
  days = sec2days(ts.time_payment.to_time - Time.now)
  old_dns = ts.dns
  cost = ((edit_params[:slots].to_i - ts.slots) * (3.to_f/30*days)).round 2
  if user.id == ts.user_id
    if user.money >= cost
      user.update money: (user.money - cost)
      if ts.update dns: edit_params[:dns], slots: edit_params[:slots]
        if old_dns != '' and edit_params[:dns] != ''
          server.edit_dns(server.dns_to_dnscfg(old_dns, ts.port),server.dns_to_dnscfg(edit_params[:dns],ts.port))
        elsif old_dns != '' and edit_params[:dns] == ''
          server.del_dns(server.dns_to_dnscfg(old_dns, ts.port))
        elsif old_dns == '' and edit_params[:dns] != ''
          server.new_dns(server.dns_to_dnscfg(edit_params[:dns],ts.port))
        end
      else
        render 'cabinet/edit'
      end
      redirect_to cabinet_home_path, notice: 'Вы успешно редактировали сервер'
    else
      redirect_to cabinet_home_path, notice: 'Недостаточно средст'
    end
  else
    redirect_to cabinet_home_path
  end
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
    if [1,2,3,6,12].include?(time)

      @ts.time_payment = time
      @ts.user_id = user.id

      cost = time * 3 * @ts.slots

        if user.money >= cost
          if @ts.valid?
            user.spent+=cost
            @ts.time_payment = Date.today + 30*time
            data=server.server_create(free_port,@ts.slots)
            @ts.machine_id=data['sid']
            @ts.port =data['virtualserver_port']
            @token=data['token']
            server.new_dns(server.dns_to_dnscfg(@ts.dns, @ts.port)) unless @ts.dns == ''
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
      render '_new'
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
      dns, port = @ts.dns, @ts.port
      if @ts.user_id == current_user.id
        server.server_destroy(@ts.machine_id)
        if @ts.destroy
          server.del_dns(server.dns_to_dnscfg(dns, port)) unless dns == ''
          redirect_to cabinet_home_path
        end
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
  @ts = Tsserver.where(id: params[:id]).take!
end

def extend_up
  s = Tsserver.where(id: params[:id]).take!
  user = current_user
  time = extend_params[:time_payment].to_i
  if [1,2,3,6,12].include?(time)
    if user.money >= (s.slots * 3)
      if user.id == s.user_id
        user.spent+=(s.slots * 3)
        user.money = user.money - (s.slots * 3)
        s.time_payment = s.time_payment + time * 30
        s.save
        user.save
        flash[:notice] = 'Вы успешно продлил'
        redirect_to cabinet_home_path
      else
        redirect_to cabinet_home_path
      end
    else
      flash[:notice] = 'Недостаточно средств'
      redirect_to cabinet_home_path
    end
  else
    redirect_to cabinet_home_path
  end
end

def work
  ts = Tsserver.where(id: params[:id]).take!
  user = current_user
  id = ts.machine_id

    if user.id == ts.user_id
      server=CabinetHelper::Server.new
      if server.server_status(id) == 'Online'
        server.server_stop id
        redirect_to cabinet_home_path
      else
        server.server_start id
        redirect_to cabinet_home_path
      end

    else
      redirect_to cabinet_home_path
    end

end




private



  def edit_params
    params.require(:tsserver).permit(:slots, :dns)
  end

	def ts_params
		params.require(:tsserver).permit(:slots, :dns, :time_payment)
  end

  def extend_params
    params.require(:tsserver).permit(:time_payment)
  end

  def sec2days(seсs)
    time = seсs.round
    time /= 60
    time /= 60
    time /= 24
    time+=2
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
