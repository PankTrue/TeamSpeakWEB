#!/bin/bash
sudo apt-get update;
sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev nodejs postfix;

#Install ruby------------------------------------------
git clone https://github.com/rbenv/rbenv.git ~/.rbenv;
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc;
echo 'eval "$(rbenv init -)"' >> ~/.bashrc;

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build;
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc;

rbenv install 2.4.0;
rbenv global 2.4.0;
ruby -v;
gem install bundler;


sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7;
sudo apt-get install -y apt-transport-https ca-certificates;

# Add Passenger APT repository
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list';
sudo apt-get update;

# Install Passenger & Nginx
sudo apt-get install -y nginx-extras passenger;

#Install Postgres
sudo apt-get install postgresql postgresql-contrib libpq-dev;


#Setting postgres
#sudo su postgres;
#psql;
#CREATE USER ts WITH PASSWORD 'pank0211';
#CREATE DATABASE "teamspeak" WITH OWNER = ts;
#\q
#exit;

#Download site
ssh-keygen;
cat .ssh/id_rsa.pub;
#add pub key on gitlab (Settings -> SSH keys)
git clone git@gitlab.com:PankTrue/TeamSpeakWEB.git;


#Bundle
bundle install --without test development;
#bundle exec rails db:migrate RAILS_ENV=production;
#bundle exec rails assets:precompile RAILS_ENV=production;

#Setting nginx
sudo cp ~/TeamSpeakWEB/deploy/nginx/passenger.conf /etc/nginx/passenger.conf
sudo cp ~/TeamSpeakWEB/deploy/nginx/nginx.conf /etc/nginx/nginx.conf;
sudo cp ~/TeamSpeakWEB/deploy/nginx/sites-enabled/teamspeak /etx/nginx/sites-enabled/teamspeak;
sudo rm /etc/nginx/sites-enabled/default;