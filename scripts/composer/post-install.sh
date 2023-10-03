#! /bin/bash
#
# Drupal install/update scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/drupal-project/
#

# just logging
echo post-install | sudo tee -a script-control.txt

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
DRUPAL_HOME=$(basename "$PWD")

# the URI for the Drupal frontend, default is the project directory
SITE_URI=$DRUPAL_HOME

# random database password for drupal site user
DRUPAL_DB_PASS=$(openssl rand -base64 16)

# DB user is the site URI without dots
DRUPAL_DB_USER="${SITE_URI//./}"

# DB name is limited to 16 chars
DRUPAL_DB_NAME="${DRUPAL_DB_USER:0:16}"

# DB host: defaults to localhost
DRUPAL_DB_HOST='localhost'

# log DB parameters
echo "DP | MySQL password of user $DRUPAL_DB_USER for DB $DRUPAL_DB_NAME is $DRUPAL_DB_PASS" > db.txt

echo "DP | --------------------------------------------------------------------"
echo "DP | A) Database settings for Drupal ..."
# retrive db root pwd:
DB_ROOT_PWD=`sudo cat /root/db.txt`
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

echo "DP | --------------------------------------------------------------------"
echo "DP | C) Set file ownerships and permissions ..."
script_user=`whoami`
web_group="www-data"
# ownerships
sudo find ./web -exec chown ${script_user}:${web_group} '{}' \+

# permissions
find ./web -type d -exec chmod 750 '{}' \+
find ./web -type f -exec chmod 640 '{}' \+

# Prepare the /sites directory: write permissions for www-data
chmod 770 sites/$SITE_URI
find ./web/sites/$SITE_URI -type d -exec chmod 770 '{}' \+
find ./web/sites/$SITE_URI -type f -exec chmod 660 '{}' \+

echo "DP | --------------------------------------------------------------------"
echo "DP | D) Configure webserver to serve the site ..."
# TBD

echo "DP | --------------------------------------------------------------------"
echo "DP | E) Running the drupal installer ..."
vendor/bin/drush topic

echo "DP | --------------------------------------------------------------------"
echo "DP | F) Finalizing file settings on fresh create folders ..."
chmod 750 sites/$SITE_URI
sudo find ./web/sites/$SITE_URI -type d -exec chmod 750 '{}' \+
sudo find ./web/sites/$SITE_URI -type f -exec chmod 640 '{}' \+
chmod 440 ./web/sites/$SITE_URI/settings.php

echo "DP | --------------------------------------------------------------------"
echo "DP | G) Cleaning up ..."
# reload services?
