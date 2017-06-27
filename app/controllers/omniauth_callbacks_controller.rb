class OmniauthCallbacksController < ApplicationController

  def vkontakte

    if request.env["omniauth.auth"].info.email.blank?
      redirect_to "/users/auth/?auth_type=rerequest&scope=email"
    end
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      flash[:success] = 'Вы успешно зарегистрировались'
      sign_in_and_redirect @user
    else
      session["devise.vkontakte_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end





end
