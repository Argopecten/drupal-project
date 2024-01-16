#! /bin/bash
#
# Drupal install/update scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/drupal-project/
#

###############################################################################
# The script runs when the post-install-cmd event is fired by composer.
# This occurs after "composer install" is executed with a composer.lock
# file present: drupal code has been deployed on the server
#  - it installs drupal main site, if no other drupal site is present
#  - it installs additional drupal site in multisite  mode, if there is one
#    drupal site
#
# Functionality:
#  - create db user and permissions for the site
#  - prepares drupal settings files and site folders
#  - set file permissions & ownership
#  - configure webserver to serve the site
#
###############################################################################

echo "DP | --------------------------------------------------------------------"
echo "DP | Site and database parameters ..."
# get Drupal project directory
DRUPAL_ROOT=$PWD
DRUPAL_HOME=$(basename "$PWD")

# the URI for the Drupal frontend, default is the project directory
SITE_URI=$DRUPAL_HOME

# generate 5x4 bits for password
DRUPAL_DB_PASS=$(pwgen 5 4 -c -n -s -B)
# replace newlines by underscore
DRUPAL_DB_PASS="${DRUPAL_DB_PASS//$'\n'/'_'}"

# DB user is the site URI without dots
DRUPAL_DB_USER="${SITE_URI//./}"

# DB name is limited to 16 chars
DRUPAL_DB_NAME="${DRUPAL_DB_USER:0:16}"

# DB host: defaults to localhost
DRUPAL_DB_HOST="localhost"

# log DB parameters
echo "mysql://$DRUPAL_DB_USER:$DRUPAL_DB_PASS@$DRUPAL_DB_HOST/$DRUPAL_DB_NAME" > db-url.conf

echo "DP | --------------------------------------------------------------------"
echo "DP | A) Database settings for Drupal ..."
# retrive db root pwd:
DB_ROOT_PWD=$(sudo cat /root/db_pwd.txt)
# Create database
sudo /usr/bin/mysql -u root -p"$DB_ROOT_PWD" -e "CREATE DATABASE $DRUPAL_DB_NAME"
# Create db user
sudo /usr/bin/mysql -u root -p"$DB_ROOT_PWD" -e "CREATE USER IF NOT EXISTS '$DRUPAL_DB_USER'@'$DRUPAL_DB_HOST' IDENTIFIED BY '$DRUPAL_DB_PASS'"
# Grant all the privileges to the Drupal database
sudo /usr/bin/mysql -u root -p"$DB_ROOT_PWD" -e "GRANT ALL ON $DRUPAL_DB_NAME.* TO '$DRUPAL_DB_USER'@'$DRUPAL_DB_HOST' WITH GRANT OPTION"

echo "DP | --------------------------------------------------------------------"
echo "DP | B) Preparing Drupal settings file and folders ..."
# create the settings.php file for the site
mkdir -p web/sites/$SITE_URI
cp web/sites/default/default.settings.php web/sites/$SITE_URI/settings.php

cat <<EOF >> web/sites/$SITE_URI/settings.php
#
# change trusted_host_patterns
# https://www.drupal.org/docs/getting-started/installing-drupal/trusted-host-settings
\$settings['trusted_host_patterns'] = [
   "^$SITE_URI$",
   "^.+\.$SITE_URI$",
];
EOF

echo "DP | --------------------------------------------------------------------"
echo "DP | C) Set file ownerships and permissions ..."
script_user=$(whoami)
web_group="www-data"
# ownerships
sudo find ./web -exec chown ${script_user}:${web_group} '{}' \+

# permissions
find ./web -type d -exec chmod 750 '{}' \+
find ./web -type f -exec chmod 640 '{}' \+

# Prepare the /sites directory: write permissions for www-data
chmod 770 ./web/sites/$SITE_URI
find ./web/sites/$SITE_URI -type d -exec chmod 770 '{}' \+
find ./web/sites/$SITE_URI -type f -exec chmod 660 '{}' \+

echo "DP | --------------------------------------------------------------------"
echo "DP | D) Configure webserver to serve the site ..."
# site config for webserver, except SSL certs!
sudo cp /usr/local/etc/nginx-config/sites.d/$(hostname -f).conf \
     /usr/local/etc/nginx-config/sites.d/$SITE_URI.conf
sudo sed -i -e "s/$(hostname -f)/$SITE_URI/" /usr/local/etc/nginx-config/sites.d/$SITE_URI.conf

echo "DP | --------------------------------------------------------------------"
echo "DP | E) Running the drupal installer ..."
# drupal site install via drush
vendor/bin/drush site-install standard --yes \
  --db-url=$(cat db-url.conf) \
  --site-name=$SITE_URI \
  --sites-subdir=$SITE_URI

# set final password for first (admin) user
echo "$(echo `pwgen 5 4 -c -n -s -B` | tr -s ' ' '_' )" > admin_pwd.txt
vendor/bin/drush user:password admin '$(cat admin_pwd.txt)' --uri=$SITE_URI

echo "DP | --------------------------------------------------------------------"
echo "DP | F) Finalizing file settings on fresh create folders ..."

sudo find ./web/sites/$SITE_URI -exec chown ${script_user}:${web_group} '{}' \+

chmod 750 ./web/sites/$SITE_URI
sudo find ./web/sites/$SITE_URI -type d -exec chmod 750 '{}' \+
sudo find ./web/sites/$SITE_URI -type f -exec chmod 640 '{}' \+
chmod 440 ./web/sites/$SITE_URI/settings.php

# /files is writeable for www-data
chmod 770 ./web/sites/$SITE_URI/files
sudo find ./web/sites/$SITE_URI/files -type d -exec chmod 770 '{}' \+
sudo find ./web/sites/$SITE_URI/files -type f -exec chmod 660 '{}' \+

echo "DP | --------------------------------------------------------------------"
echo "DP | G) Cleaning up ..."
# reload services
sudo systemctl reload nginx
