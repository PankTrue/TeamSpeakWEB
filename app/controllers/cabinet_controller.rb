class CabinetController < ApplicationController
helper CabinetHelper
require 'date'
require 'base64'
	before_action :authenticate_user!
	before_action :ts_params, only: [:create]
  before_action :edit_params, only: [:update]
  before_action :extend_params, only: [:extend_up]

def home
    @servers = Tsserver.where(user_id: current_user.id).select(:machine_id)
    servs = Array.new
     @servers.each do |temp|
        servs << temp.machine_id
     end
    server = Teamspeak::Functions.new
    @status = server_status(server.server_list, servs)
    server.disconnect
end

def edit
  @ts = Tsserver.where(id: params[:id]).take!
  redirect_to cabinet_home_path unless @ts.user_id == current_user.id
  @days = sec2days(@ts.time_payment.to_time - Time.now)
end

def update
  @ts = Tsserver.where(id: params[:id]).take!
  user = User.where(id: current_user.id).take!
  server = Teamspeak::Functions.new
  other = Teamspeak::Other.new
  days = sec2days(@ts.time_payment.to_time - Time.now)
  old_dns = @ts.dns
  cost = (((edit_params[:slots].to_i - @ts.slots) * (3.to_f/30*days))).round 2
  cost += 10 if old_dns != edit_params[:dns]
  if user.id == @ts.user_id
    if user.money >= cost
      if @ts.valid?
        if @ts.update dns: edit_params[:dns], slots: edit_params[:slots]
          user.update! money: ((user.money - cost).round 2), spent: user.spent+=cost
          server.server_edit_slots @ts.machine_id, edit_params[:slots]
          if !old_dns.empty? and !edit_params[:dns].empty?
            other.edit_dns(old_dns, @ts.port,edit_params[:dns],@ts.port)
          elsif !old_dns.empty? and edit_params[:dns].empty?
            other.del_dns(old_dns, @ts.port)
          elsif old_dns.empty? and !edit_params[:dns].empty?
            other.new_dns(edit_params[:dns],@ts.port)
          end
          redirect_to cabinet_home_path, notice: 'Вы успешно редактировали сервер'
        else
          render 'cabinet/edit'
        end
      end
    else
      redirect_to cabinet_home_path, notice: 'Недостаточно средст'
    end
  else
    redirect_to cabinet_home_path
  end
  server.disconnect
end


def new
  @ts=Tsserver.new
end


def create
  server=Teamspeak::Functions.new
  other = Teamspeak::Other.new
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
            other.new_dns(@ts.dns, @ts.port) unless @ts.dns.empty?
            @ts.save
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
      render 'new'
    end

server.disconnect
end



def destroy
  server=Teamspeak::Functions.new
  other = Teamspeak::Other.new
    @ts = Tsserver.find(params[:id])
      dns, port = @ts.dns, @ts.port
      if @ts.user_id == current_user.id
        server.server_destroy(@ts.machine_id)
        if @ts.destroy
          other.del_dns(dns, port) unless dns.empty?
          redirect_to cabinet_home_path
        end
      else
        redirect_to cabinet_home_path
      end

server.disconnect
end

def extend
  @ts = Tsserver.where(id: params[:id]).take!
  redirect_to cabinet_home_path unless @ts.user_id == current_user.id
end

def extend_up
  s = Tsserver.where(id: params[:id]).take!
  user = current_user
  time = extend_params[:time_payment].to_i
  cab = Teamspeak::Functions.new
  if [1,2,3,6,12].include?(time)
    if user.money >= (s.slots * 3 * time)
      if user.id == s.user_id
        user.spent+=(s.slots * 3 * time)
        user.money = user.money - (s.slots * 3 * time)
        s.state = true
        if Date.today < s.time_payment
          s.time_payment = s.time_payment + time * 30
        else
          s.time_payment = Date.today + time * 30
          cab.server_start(s.machine_id)
          cab.server_autostart s.machine_id, 1
        end
        if s.save validate:false and user.save
          flash[:notice] = 'Вы успешно продлил'
          redirect_to cabinet_home_path
        end
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
  cab.disconnect
end

def work
  ts = Tsserver.where(id: params[:id]).take!
  id = ts.machine_id
      if current_user.id == ts.user_id
        if ts.state
          server=Teamspeak::Functions.new
          if server.server_status(id)
            server.server_stop id
            redirect_to cabinet_home_path
          else
            server.server_start id
            redirect_to cabinet_home_path
          end
          server.disconnect
        else
          redirect_to cabinet_home_path, notice: 'Продлите сервер'
        end
      else
        redirect_to cabinet_home_path
      end
end

def pay
  @w1 = Hash.new
  @w1 = {
      merchant_id: Settings_Walletone.merchant_id,
      description: "BASE64:#{Base64.encode64("Пополнение баланса user_id: #{current_user.id}")}",
      signature: generate_signature
  }

end

def free_dns
  dns_list = Tsserver.pluck(:dns)
  status = dns_list.include?(params[:dns]) ? true:false
  respond_to do |format|
    format.json { render :json => {status: status} }
  end
end

def edit_auto_extension
  current_user.update auto_extension: params[:auto_extension]
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




  def free_port
    i=2000
    server=Teamspeak::Functions.new
    data=server.server_list
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
    server.disconnect
  end

  def generate_signature
    data = params.clone
    data.delete('WMI_SIGNATURE')
    data = data.sort
    values = data.map {|key,val| val}
    signature_string = values + @options[:secret]
    Digest::MD5.base64digest(signature_string)
  end

  def server_status(server_list, user_servers)
    arr = Array.new
    server_list.each do |temp|
      if user_servers.include?(temp["virtualserver_id"])
        arr << temp["virtualserver_id"]
        arr << temp["virtualserver_status"]
      end
    end
    arr
  end

  def sec2days(sec)
    time = sec.round
    time /= 60
    time /= 60
    time /= 24
    time+=2
  end

end
