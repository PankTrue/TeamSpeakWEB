# Base image:
FROM ruby:2.3.1
 
# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
 
# Set an environment variable where the Rails app is installed to inside of Docker image:
ENV RAILS_ROOT /var/www/teamspeak
RUN mkdir -p $RAILS_ROOT
 
# Set working directory, where the commands will be ran:
WORKDIR $RAILS_ROOT
 
# Gems:
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN gem install bundler
RUN bundle install
 
COPY config/puma.rb config/puma.rb
 
# Copy the main application.
COPY . .
 
EXPOSE 3000
#RUN bin/rails db:create RAILS_ENV=production
#RUN bin/rails db:migrate RAILS_ENV=production
 
# The default command that gets ran will be to start the Puma server.
CMD bundle exec puma -C config/puma.rb
