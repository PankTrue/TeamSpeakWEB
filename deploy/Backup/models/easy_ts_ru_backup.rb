gem 'settingslogic'

require 'settingslogic'


# class Database < Settingslogic
#   source "~/teamspeakweb/config/database.yml"
#   namespace "production"
# end
#
# class Settings < Settingslogic
#   source "~/teamspeakweb/config/settings.yml"
#   namespace "production"
# end


class Database < Settingslogic
  source "/home/pank/Projects/teamspeakweb/config/database.yml"
  namespace "production"
end

class Settings < Settingslogic
  source "/home/pank/Projects/teamspeakweb/config/settings.yml"
  namespace "production"
end


# $ backup perform -t easy_ts_ru_backup [-c <path_to_configuration_file>]

Backup::Model.new(:backup, 'Backup database for site and tsserver') do
  ##
  # Split [Splitter]
  #
  # Split the backup file in to chunks of 250 megabytes
  # if the backup file size exceeds 250 megabytes
  #
  split_into_chunks_of 250

  ##
  # PostgreSQL [Database]
  #

  database PostgreSQL do |db|
    db.name               = Database.database
    db.username           = Database.username
    db.password           = Database.password
    db.host               = "localhost"
    db.port               = 5432
    db.socket             = "/tmp/pg.sock"
    db.additional_options = ["-xc", "-E=utf8"]
  end

  ##
  # Dropbox File Hosting Service [Storage]
  #
  # Access Type:
  #
  #  - :app_folder (Default)
  #  - :dropbox
  #
  # Note:
  #
  #  Initial backup must be performed manually to authorize
  #  this machine with your Dropbox account.
  store_with Dropbox do |db|
    db.api_key     = Settings.backup.dropbox.key
    db.api_secret  = Settings.backup.dropbox.secret
    db.access_type = :app_folder
    db.path        = Settings.backup.dropbox.path
    db.keep        = 25
  end

  ##
  # Bzip2 [Compressor]
  #
  compress_with Bzip2

end
