class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :omniauthable

   has_many :tsservers
   has_many :payments

  TEMP_EMAIL_PREFIX = 'change@me'
  TEMP_EMAIL_REGEX = /\Achange@me/

  #validates_format_of :email, :without => TEMP_EMAIL_REGEX, on: :update

  def self.from_omniauth(auth, signed_in_resource = nil)

    user = signed_in_resource ? signed_in_resource : where(provider: auth.provider, uid: auth.uid).first

    if user.nil?
      email_is_verified = auth.info.email && (auth.info.verified || auth.info.verified_email)
      email = auth.info.email if email_is_verified
      user = User.where(:email => email).first if email

      # Create the user if it's a new registration
      if user.nil? #If not found email in database
        user = User.new(
            email: email ? email : "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
            password: Devise.friendly_token[0,20],
            provider: auth.provider,
            uid: auth.uid
        )
        user.skip_confirmation!
        user.save!
      else
        user.provider, user.uid = auth.provider, auth.uid
      end
    end
    return user
  end



  def email_verified?
    self.email && self.email !~ TEMP_EMAIL_REGEX
  end


end
