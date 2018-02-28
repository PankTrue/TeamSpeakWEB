class Audiobot < ApplicationRecord
  belongs_to :user

  validates :address, format: {with: /[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}(.[a-zA-Z]{2,63})?/  , message: "неверно введен"}
  # validates :address, format: {with: /(([0-9]{1,3}\\.){3})[0-9]{1,3}/  , message: "ip is not valid"}



end
