#/bin/bash

SCRIPTDIR=$(dirname $0)
SETTINGS=$SCRIPTDIR/../../../utils-private/etc/vimeo.rc
if [ ! -f ${SETTINGS} ]
then
    echo "Can't find file $SETTINGS"
    exit 1
fi
. ${SETTINGS}

CHANNEL=$1

if [ "$CHANNEL" = "" ]
then
    echo "Missing channel"
    exit 2
fi


i=0;
TMP_FILE=/tmp/vimeo-channels-$USER.json
CH_NAME=$(curl -H A"uthorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/channels/$CHANNEL?fields=name"| jq '.name' | sed 's,",,g')
curl -H "Authorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/channels/$CHANNEL/videos?fields=name,link&sort=manual" -s \
    | jq -r '.data[]|.name,.link' \
         > ${TMP_FILE}

cat ${TMP_FILE} | while read apa; \
    do if [[ $((i++%2==1)) -eq 0 ]]; \
       then name=$apa; \
       else URL=$apa;echo "<a href=\"$URL\">$name</a>"; \
       fi; \
    done

echo "[https://vimeo.com/channels/$CHANNEL $CH_NAME]"
cat ${TMP_FILE} | while read apa; \
    do if [[ $((i++%2==1)) -eq 0 ]]; \
       then name=$apa; \
       else URL=$apa;echo "* [$URL $name]"; \
       fi; \
    done
