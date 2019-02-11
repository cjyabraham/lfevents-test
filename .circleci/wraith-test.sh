#!/bin/bash

if [[ (${CIRCLE_BRANCH} != "master" && -z ${CIRCLE_PULL_REQUEST+x}) || (${CIRCLE_BRANCH} == "master" && -n ${CIRCLE_PULL_REQUEST+x}) ]];
then
    echo -e "CircleCI will only run Wraith tests on Pantheon if on the master branch or creating a pull requests.\n"
    exit 0;
fi

# Bail if required environment varaibles are missing
if [ -z "$TERMINUS_SITE" ] || [ -z "$TERMINUS_ENV" ]
then
  echo 'No test site specified. Set TERMINUS_SITE and TERMINUS_ENV.'
  exit 1
fi

echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo "Wraith test site: $TERMINUS_SITE.$TERMINUS_ENV"
echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo

# Exit immediately on errors
set -ex

# Clear site cache
terminus -n env:clear-cache $TERMINUS_SITE.$TERMINUS_ENV

# Set Behat variables from environment variables
# export BEHAT_PARAMS='{"extensions":{"Behat\\MinkExtension":{"base_url":"https://'$TERMINUS_ENV'-'$TERMINUS_SITE'.pantheonsite.io"},"PaulGibbs\\WordpressBehatExtension":{"site_url":"https://'$TERMINUS_ENV'-'$TERMINUS_SITE'.pantheonsite.io/wp","users":{"admin":{"username":"'$ADMIN_USERNAME'","password":"'$ADMIN_PASSWORD'"}},"wpcli":{"binary":"terminus -n wp '$TERMINUS_SITE'.'$TERMINUS_ENV' --"}}}}'
# export RELOCATED_WP_ADMIN=TRUE

# Wake the multidev environment before running tests
terminus -n env:wake $TERMINUS_SITE.$TERMINUS_ENV

# Ping wp-cli to start ssh with the app server
terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- cli version

# Run the Wraith tests
cd wraith
cp configs/capture.yaml.template configs/capture.yaml 
cat >>configs/capture.yaml <<EOL
# (required) The domains to take screenshots of.
domains:
  current:  "http://live-lfevents-test.pantheonsite.io"
  new:      "http://$TERMINUS_SITE.$TERMINUS_ENV"
EOL
wraith capture capture

# Change back into previous directory
cd -