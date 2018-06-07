require "settingslogic"


class DatabaseCfg < Settingslogic
  source "/home/ts/teamspeakweb/config/database.yml"
  namespace "production"
end

class Settings < Settingslogic
  source "/home/ts/teamspeakweb/config/settings.yml"
  namespace "production"
end


# class DatabaseCfg < Settingslogic
#   source "/home/pank/Projects/teamspeakweb/config/database.yml"
#   namespace "production"
# end
#
# class Settings < Settingslogic
#   source "/home/pank/Projects/teamspeakweb/config/settings.yml"
#   namespace "production"
# end


# encoding: utf-8

##
# Backup Generated: backup
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t backup [-c <path_to_configuration_file>]
#
Model.new(:backup, 'Description for backup') do


  database PostgreSQL do |db|
   db.name               = DatabaseCfg.database
   db.username           = DatabaseCfg.username
   db.password           = DatabaseCfg.password
   db.host               = "localhost"
   db.port               = 5432
  end

  archive :tsserver do |archive|
    archive.root Settings.teamspeak.ts_path
    archive.add "ts3server.sqlitedb"
    archive.add "tsdns/tsdns_settings.ini"
  end


  #TODO: backup audiobot configs
  # achive :audiobot do |archive|
  #   archive.root Settings.audiobot.
  # end


  store_with Dropbox do |db|
    db.api_token    = Settings.backup.dropbox.token
    db.path         = Settings.backup.dropbox.path
    db.keep         = Time.now - 604800 #1 week
  end

  compress_with Bzip2

end