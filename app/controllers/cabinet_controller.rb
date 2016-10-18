class CabinetController < ApplicationController
include CabinetHelper
require 'date'
	before_action :authenticate_user!
	before_action :ts_params, only: [:create]
  def home
   @user=current_user
   # server=CabinetHelper::Server.new
   # @data=server.serverlist
   @status = CabinetHelper::Server.new

  end

  def new
  	@ts=Tsserver.new
  end

def create
  @ts = Tsserver.new(ts_params)
  time = @ts.time_payment
  date = Time.now
  date = date.to_date
  date = date >> time.to_i
  @ts.time_payment = date

 # if @ts.valid
    @ts.user_id = current_user.id
    server=CabinetHelper::Server.new
    data=server.server_create(free_port,@ts.slots)
    @ts.machine_id=data['sid']
    @ts.port=data['virtualserver_port']
    @token=data['token']

    @ts.save
      flash[:notice] = "Ваш ключ: #{@token}"
      redirect_to cabinet_home_path
 # else
   # flash[:notice] = "No valid data"
  #end
end



  def destroy
    if @ts = Tsserver.where(id: params[:id]).first
      if @ts.user_id == current_user.id
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
		params.require(:tsserver).permit(:slots, :dns, :time_payment)
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
