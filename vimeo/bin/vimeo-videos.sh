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
TODAY_VI=/tmp/vimeo-videos-${TODAY}.txt

if [ ! -f $TODAY_VI ]  || [ "$1" = "-f" ]
then
    rm $TODAY_VI
    LAST_PAGE=$(curl -H "Authorization: Bearer ${VIMEO_BEARER} " 'https://api.vimeo.com/me/videos?fields=link&per_page=100' -s|grep last|rev|cut -d '=' -f1|tr -d '"')
    
    for i in $(seq 1 $LAST_PAGE)
    do
        curl -H "Authorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/me/videos?per_page=100&fields=uri&page=$i" -s|grep '"uri"'|sed -e 's/\(.*s\/\)\([0-9]*\)\("\)/\2/' >> $TODAY_VI
    done 

#    curl -H "Authorization: Bearer ${VIMEO_BEARER}" 'https://api.vimeo.com/me/videos?fields=link&per_page=100' -s|grep last|rev|cut -d '=' -f1|tr -d '"' 
#    for c in $(./vimeo-channels.sh  )
 #   do
        #    echo "Channel: $c"
  #      curl -H "Authorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/channels/$c/videos?fields=name,link" -s \
   #         | jq -r '.data[]|.name,.link' | grep "https://vimeo" | sed 's,\/, ,g' | awk ' { print $3}'
   # done > $TODAY_VI
    

fi
cat $TODAY_VI
