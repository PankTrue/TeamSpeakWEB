class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:vkontakte]

   has_many :tsservers
   has_many :payments




  def self.from_omniauth(auth)
    # if where(email: auth.info.email).first
      where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.provider = auth.provider
        user.uid = auth.uid
        user.email = auth.info.email if user.email.blank?
        user.password = Devise.friendly_token[0,20] if user.password.blank?
      end
    # else

    # end
  end




end
