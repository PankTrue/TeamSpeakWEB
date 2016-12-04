class W1Controller < ApplicationController
  before_action :create_notification
  skip_before_action :verify_authenticity_token

  def callback
    if @notification.acknowledge
      # Получаем значение ID пользователя и номер заказа
      user_id, order_no = @notification.item_id.split('_')
      # Ищем подписку по номеру заказа
      subscription = Subscription.where(order_no: order_no).first
      #.... Ваши действия
      render :text => @notification.success_response
    else
      head :bad_request
    end
  end

  def success
  end

  def fail
  end



  private

  def create_notification
    @notification = W1::Notification.new(request.raw_post, :secret => Billing::W1.signature)
  end

end