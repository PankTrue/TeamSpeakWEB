class CabinetController < ApplicationController
include CabinetHelper
	before_action :authenticate_user!
	before_action :ts_params, only: [:create]
  def home
  	@user=user_data
    server=CabinetHelper::Server.new
    @data=server.serverlist
  end

  def new
  	@ts=Tsserver.new
  end

  def create
  	@ts = Tsserver.new(ts_params)
  	@ts.user_id = user_data.id
  	@ts.time_payment = Time.now
    if @ts.valid?
    server=CabinetHelper::Server.new
    data=server.server_create(free_port,@ts.slots)
    @ts.machine_id=data['sid']
    @ts.port=data['virtualserver_port']
    @token=data['token']

    	if @ts.save
    		flash[:notice] = "Ваш ключ: #{@token}"
        redirect_to cabinet_home_path
      else
        render :new
    	end
    end
  end

  def destroy
    if @ts = Tsserver.where(id: params[:id]).first
      if @ts.user_id == user_data.id
        server=CabinetHelper::Server.new
        server.server_destroy(@ts.machine_id)
        @ts.destroy
        redirect_to cabinet_home_path
      else
        redirect_to cabinet_home_path
      end
    else
      redirect_to cabinet_home_path
    end
  end




private
	def ts_params
		params.require(:tsserver).permit(:slots, :dns)
	end

	def user_data
  		user=User.find(current_user)
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
