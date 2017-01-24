class UnitpayController < ApplicationController
  include Unitpay::Controller
  skip_before_filter :verify_authenticity_token

  def success
    # вызывается при отправке шлюзом пользователя на Success URL.
    #
    # ВНИМАНИЕ: является незащищенным действием!
    # Для выполнения действий после успешной оплаты используйте pay
  end

  def fail
    # вызывается при отправке шлюзом пользователя на Fail URL.
    # (во время принятия платежа возникла ошибка)
  end

  private

  def pay
    # вызывается при оповещении магазина об
    # успешной оплате пользователем заказа и после проверки сигнатуры.
    #
    # ВНИМАНИЕ: правильный ответ будет сгенерирован автоматически (не нужно использовать render\redirect_to)!
    # order = Order.find(params[:params][:account])
    # order.payed!
  end

  def error
    # вызывается при оповещении магазина об ошибке при оплате заказа.
    # При отсутствии логики обработки ошибок на стороне приложения оставить метод пустым.
    #
    # ВНИМАНИЕ: правильный ответ будет сгенерирован автоматически (не нужно использовать render\redirect_to)!
    # puts params[errorMessage]
    # => Текст ошибки, присланный unitpay
  end

  def service
    # ВНИМАНИЕ: обязательный метод! Используется при проверке сигнатуры.
    Unitpay::Service.new('unitpay_public_key', 'unitpay_secret_key')
  end
end