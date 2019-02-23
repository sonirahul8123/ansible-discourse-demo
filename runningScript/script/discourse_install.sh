#!/usr/bin/env bash

log_info() {
  printf "\n\e[0;35m $1\e[0m\n\n"
}

error_info() {
  printf "\n\e[0;31m $1\e[0m\n\n"
}

log_info "Installing Docker and Git ..."
  sudo wget -qO- https://get.docker.com/ | sh

log_info "Cloning discourse from github ..."
  sudo mkdir -p /var/discourse
  sudo git clone https://github.com/sonirahul8123/discourse_docker.git /var/discourse
  sudo chown -R root:ubuntu /var/discourse
  cd /var/discourse


log_info "Configuring launcher file ..."
  sudo sed -i '/while \[\[ \"\$config_ok/{N;s/$/\n\n    hostname="www.webengagediscourse.tk"\n    developer_emails="soni.rahul073@gmail.com"\n    smtp_address="smtp.sendgrid.net"\n    smtp_port="587"\n    smtp_user_name="apikey"\n    letsencrypt_account_email="soni.rahul073@gmail.com"\n/}' discourse-setup
  sudo sed -i 's/smtp_password="$new_value"/smtp_password="your smtp api key here"/' discourse-setup

log_info "Initializing launcher ..."
  sudo bash ./discourse-setup

result=$?
if [ $result -eq 0 ]; then
  log_info "Congratulations, installation has been completed ..!! Visit your registered domain in browser."
else
  error_info "Something is wrong, please check the script :("
