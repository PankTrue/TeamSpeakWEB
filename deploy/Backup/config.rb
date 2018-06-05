Backup::Logger.configure do
  logfile.max_bytes = 500_000         # Default: 500_000
end
##
# Load all models from the models directory.
Dir[File.join(File.dirname(Config.config_file), "models", "*.rb")].each do |model|
  instance_eval(File.read(model))
end
