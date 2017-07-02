class UserMailer < ApplicationMailer
  default from: 'info@easy-ts.ru',
          template_path: 'mailers/users'

  def info_for_extend_server(user, ts)
      @user = user
      @ts = ts
      mail(to: @user.email, subject: 'Заканчивается оплаченный срок для услуг')
  end
  
end
