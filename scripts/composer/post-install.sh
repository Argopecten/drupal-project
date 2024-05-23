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
###############################################################################

echo "DP | --------------------------------------------------------------------"
# Hide Symfony\console\Input of Drupal to trigger it in drush8
mv ./vendor/symfony/console/Input ./vendor/symfony/console/_hide_Input
