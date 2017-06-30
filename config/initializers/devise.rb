# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|

  config.mailer_sender = 'info@easy-ts.ru'
  require 'devise/orm/active_record'

   config.authentication_keys = [:email]
  config.case_insensitive_keys = [:email]

  config.strip_whitespace_keys = [:email]

  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 11

  config.reconfirmable = true

   config.confirmation_keys = [:email]

  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete



  config.omniauth :vkontakte, Settings.oauth.vkontakte.key, Settings.oauth.vkontakte.private, scope: 'email', info_fields: 'email,name'
  config.omniauth :facebook, Settings.oauth.facebook.key, Settings.oauth.facebook.private
  config.omniauth :google_oauth2, Settings.oauth.google_oauth2.key, Settings.oauth.google_oauth2.private
  config.omniauth :twitter, Settings.oauth.twitter.key, Settings.oauth.twitter.private, callback_url: ''
end


