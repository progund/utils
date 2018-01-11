#!/bin/bash

SCRIPTDIR=$(dirname $0)
# file with Beaerer defined in variable VIMEO_BEARER
SETTINGS=$SCRIPTDIR/../../../utils-private/etc/vimeo.rc
if [ ! -f ${SETTINGS} ]
then
    echo "Can't find file $SETTINGS"
    exit 1
fi
. ${SETTINGS}

TODAY=$(date '+%Y%m%d')
TODAY_CH=/tmp/vimeo-channels-${TODAY}.txt

if [ ! -f $TODAY_CH ]  || [ "$1" = "-f" ]
then
    curl -H "Authorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/me/channels?per_page=100&fields=uri,name&page=1" -s \
        | grep "uri" \
        | awk '{ print $2 }' \
        | sed -e 's,",,g' -e 's,\/channels\/,,g' -e 's/,//g'\
        | grep -v "per_page=" > $TODAY_CH
fi
cat $TODAY_CH


