#!/bin/bash

# Load closest mirrors

sed -i '1ideb mirror://mirrors.ubuntu.com/mirrors.txt xenial main restricted universe multiverse' /etc/apt/sources.list;
sed -i '2ideb mirror://mirrors.ubuntu.com/mirrors.txt xenial-updates main restricted universe multiverse' /etc/apt/sources.list;
sed -i '3ideb mirror://mirrors.ubuntu.com/mirrors.txt xenial-backports main restricted universe multiverse' /etc/apt/sources.list;
sed -i '4ideb mirror://mirrors.ubuntu.com/mirrors.txt xenial-security main restricted universe multiverse' /etc/apt/sources.list;

# apt update

apt-get update;

# Install dependencies

apt-get install git ufw redis-server nano fail2ban imagemagick curl sudo postgresql-9.5 postgresql-contrib-9.5 build-essential libssl-dev libyaml-dev git libtool libxslt-dev libxml2-dev libpq-dev gawk -y;

# configure & start fail2ban

cd /etc/fail2ban;
cp jail.conf jail.local;
service fail2ban start

# configure ufw

ufw allow http;
ufw allow https;
ufw allow ssh;
yes y | ufw enable;

# update crontab for discourse auto-start
sed -i '11i@reboot root bash /var/www/discourse/startup.sh' /etc/crontab;

# create directory for discourse web content
mkdir -p /var/www/discourse

# make discourse sudoer

sed -i '/ALL=(ALL:ALL) ALL/adiscourse    ALL=(ALL:ALL) ALL' /etc/sudoers;

read -s -p "Enter a Password for the Discourse User : " psss;
yes "$psss" | sudo adduser --shell /bin/bash --gecos 'Discourse application' discourse;
sudo install -d -m 755 -o discourse -g discourse /var/www/discourse;

# get ansible-discourse-demo
cd /tmp;
git clone https://github.com/sonirahul8123/ansible-discourse-demo.git;

# get latest nginx

yes | sudo apt-get remove '^nginx.*$';
cat << 'EOF' | sudo tee /etc/apt/sources.list.d/nginx.list
deb http://nginx.org/packages/ubuntu/ xenial nginx
deb-src http://nginx.org/packages/ubuntu/ xenial nginx

EOF

curl http://nginx.org/keys/nginx_signing.key | sudo apt-key add -;
sudo apt-get update && sudo apt-get -y install nginx;
cp /tmp/ansible-discourse-demo/discourse.conf /etc/nginx/conf.d/discourse.conf;
sudo mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.disabled;
mkdir /var/nginx;
service nginx restart;
sudo -u postgres createuser -s discourse;

# Install rvm

su discourse <<'EOF'

sudo apt-get install rubygems -y;
\curl -sSL https://get.rvm.io | bash
source /home/discourse/.rvm/scripts/rvm

# Install gems and discourse

sudo git clone https://github.com/discourse/discourse.git -b tests-passed --single-branch /var/www/discourse
cd /var/www/discourse
sudo gem install bundler
sudo apt-get install ruby-dev ruby2.3-dev -y;
cd  /var/www
sudo chown discourse:discourse discourse -R
cd discourse
bundle install --deployment --without test
cp /tmp/ansible-discourse-demo/startup.sh /var/www/discourse/startup.sh

EOF

# Configure Discourse

cd /var/www/discourse/config;
sudo cp discourse_defaults.conf discourse.conf;
sed -i "/^smtp_address/ s/$/ smtp.mandrillapp.com /" discourse.conf;
sed -i 's/25/587/g' discourse.conf;
read -p "Enter the name of your domain [ex: www.webeindustry.com] " domain;
sed -i "s/"www.example.com"/$domain/g" discourse.conf;
sed -i "/^server_name _ / s/_ ;$/ $domain/g" /etc/nginx/conf.d/disco.conf;
read -p "Enter your MandrillApp Username [ex: admin@mandrillapp.com] " uname;
sed -i "/^smtp_user_name/ s/$/ $uname/g" discourse.conf;
read -p "Enter your MandrillApp API Key [ex: ytCARGJVKfLJs3x6MQZqw] " API;
sed -i "/^smtp_password/ s/$/ $API/g" discourse.conf;
read -p "Enter the email address you use to register your account [ex: webeindustry@gmail.com] " mail;
sed -i "/^developer_email/ s/$/ $mail/g" discourse.conf;

# init-db

su discourse <<'EOF'

cd /var/www/discourse
createdb discourse
/bin/bash --login
RUBY_GC_MALLOC_LIMIT=90000000 RAILS_ENV=production bundle exec rake db:migrate
RUBY_GC_MALLOC_LIMIT=90000000 RAILS_ENV=production bundle exec rake assets:precompile
mkdir /var/www/discourse/tmp/pids

EOF

#final config tweaks

cd /var/www/discourse/config;
sed -i '27iexport UNICORN_SIDEKIQS=1' unicorn_upstart.conf;
cp unicorn_upstart.conf /etc/init/disc.conf;
cp nginx.global.conf /etc/nginx/conf.d/local-server.conf;

#reboot to clean up and auto-start
#echo "Shutting Down to Finalize Installation";
#sudo reboot
