class W1Controller < ApplicationController
  before_action :create_notification
  skip_before_action :verify_authenticity_token

  def callback
    wm = Walletone::Middleware::Callback.new do |notify, env|
      # notify is a Walletone::Notification instance

      raise 'WARNING! Wrong signature!' unless notify.valid? W1_SECRET_KEY

      if notify.accepted?
        # Successful payed. Deliver your goods to the client
      else
        # Payment is failed. Notify you client.
      end

      'Return some message for OK response'
    end
  end

  def success
  end

  def fail
  end



  private



end