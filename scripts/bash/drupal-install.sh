#! /bin/bash
#
# Drupal install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/drupal-project/
#

usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
[ $# -eq 0 ] && usage

# Install LAMP components for Aegir
echo "DI | ------------------------------------------------------------------"
echo "DI | A) Site parameter ..."

# u: site URL: drupal.local
while getopts 'u:' OPTION; do
  case "$OPTION" in
    u) # site URI
      SITE_URI="$OPTARG"
      echo "SITE_URI is ${OPTARG}"
      ;;
    h | *) # Display help.
      usage
      exit 1
      ;;
  esac
done

echo "DI | --------------------------------------------------------------------"
echo "DI | B) Prepare drupal folder ..."

# get Drupal project directory
DRUPAL_HOME="/var/drupal"

if [ ! -d "${DRUPAL_HOME}" ] ; then
  # create missing /var/drupal folder
  sudo mkdir ${DRUPAL_HOME}
  sudo chown `whoami` ${DRUPAL_HOME}
else
  # clean up previous site folder if any
  [[ -f "${DRUPAL_HOME}/$SITE_URI" ]] && sudo rm -rf "${DRUPAL_HOME}/$SITE_URI"
fi

# Create project from composer.json
echo "DI | ------------------------------------------------------------------"
echo "DI | C) Installing Drupal with Composer ..."

composer create-project argopecten/drupal-project \
         --no-interaction \
         --repository '{"type": "vcs","url":  "https://github.com/argopecten/drupal-project"}' \
         "${DRUPAL_HOME}/$SITE_URI"
