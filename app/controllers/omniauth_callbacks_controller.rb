class OmniauthCallbacksController < ApplicationController

  def self.provides_callback_for(provider)
    class_eval %Q{
      def #{provider}
        @user = User.from_omniauth(env["omniauth.auth"], current_user)
        Rails.logger.info env["omniauth.auth"]
        if @user.persisted?
          flash[:success] = 'Вы успешно авторизовались!'
          sign_in_and_redirect @user, event: :authentication
        else
          session["devise.#{provider}_data"] = env["omniauth.auth"]
          redirect_to new_user_registration_url
        end
      end
    }
  end

  [:twitter, :facebook, :vkontakte, :google_oauth2].each do |provider|
    provides_callback_for provider
  end


  def failure
      redirect_to new_user_registration_path, fail: 'Что-то пошло не так. Напишите об этой проблеме администрации или побробуйте позже.'
  end




end
