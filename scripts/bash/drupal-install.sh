#! /bin/bash
#
# Drupal install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/drupal-project/
#

usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
[ $# -eq 0 ] && usage

# Install LAMP components for Aegir
echo "DP | ------------------------------------------------------------------"
echo "DP | A) Site parameter ..."

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

# Install LAMP components for Aegir
echo "DP | ------------------------------------------------------------------"
echo "DP | B) Installing Drupal with Composer ..."

composer create-project argopecten/drupal-project \
         --no-interaction \
         --repository '{"type": "vcs","url":  "https://github.com/argopecten/drupal-project"}' \
         $SITE_URI
