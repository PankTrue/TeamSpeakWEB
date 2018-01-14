class AudiobotController < ApplicationController

  before_action :authenticate_user!
  before_action :audiobot_params, only: [:create]
  before_action :own_bot,only: [:edit,:update,:destroy,:panel]

  def new
    @audiobot = Audiobot.new()
  end

  def create
    @audiobot = Audiobot.new(audiobot_params)

    if [1,2,3,6,12].include?(params[:audiobot][:time_payment].to_i)
      @audiobot.user_id = current_user.id
      cost = params[:audiobot][:time_payment].to_i * 0.5 * params[:audiobot][:audio_quota].to_i
      @audiobot.time_payment = Date.today + 30 * params[:audiobot][:time_payment].to_i

      if current_user.have_money?(cost)
        if @audiobot.valid?
          if @audiobot.save and current_user.update(money: ((current_user.money - cost).round(2)), spent: current_user.spent+cost)
            redirect_to cabinet_home_path, success:'Вы успешно купили аудио бота'
          else
            redirect_to cabinet_new_path(@audiobot), danger: 'Что-то пошло не так, отпишите администрации чтобы они это починили.'
          end
        else
            render audiobot_new_path @audiobot
        end
      else
        redirect_to cabinet_home_path, danger:'Недостаточно средств'
      end
    else
      render 'new'
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  def panel
  end


private

  def own_bot
    @bot = Audiobot.find params[:id]
    redirect_to cabinet_home_path, danger: 'Нет доступа' unless current_user.id == @bot.user_id or Settings.other.admin_list.include?(current_user.email)
  end

  def audiobot_params
      params.require(:audiobot).permit(:audio_quota, :time_payment)
  end

end
