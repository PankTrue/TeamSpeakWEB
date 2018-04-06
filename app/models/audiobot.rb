class Audiobot < ApplicationRecord
  belongs_to :user

  AUDIO_FORMATS = ['mp3','m4a','opus']
  AUDIO_FORMATS_REGEXP = /\.(#{AUDIO_FORMATS.join('|')})\z/

  validates :address, format: {with: /\A(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|((\*\.)?([a-zA-Z0-9-]+\.){0,5}[a-zA-Z0-9-][a-zA-Z0-9-]+\.[a-zA-Z]{2,63}?))(:[0-9]{1,5}){0,1}\z/   , message: "неверно введен"}
  validates :server_id,inclusion: {in: 0..Settings.other.ip.size,message: 'нет в списке'}

  # validates_size_of :audio_files, maximum: 8.megabytes, message: 'Размер превышает норму'
  # validates_format_of :audio_files, with: %r{\.(mp3|opus|m4a)\z}i, message: 'Формат не поддерживается. Список поддерживаемых форматов: mp3,opus,m4a'


end
