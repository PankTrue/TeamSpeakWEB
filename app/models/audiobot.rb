class Audiobot < ApplicationRecord
  belongs_to :user


  validates :address, format: {with: /\A(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|((\*\.)?([a-zA-Z0-9-]+\.){0,5}[a-zA-Z0-9-][a-zA-Z0-9-]+\.[a-zA-Z]{2,63}?))(:[0-9]{1,5}){0,1}\z/   , message: "неверно введен"}


end
