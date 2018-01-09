#/bin/bash

SCRIPTDIR=$(dirname $0)
# file with Beaerer defined in variable VIMEO_BEARER
SETTINGS=$SCRIPTDIR/../../../utils-private/etc/vimeo.rc
if [ ! -f ${SETTINGS} ]
then
    echo "Can't find file $SETTINGS"
    echo "Trying to clone repo"
#    git clone git@github.com:progund/utils-private.git
#    RET=$?
#    cd -
#    if [ $RET -ne 0 ] || [ ! -f ${SETTINGS} ]
#    then
        echo "failed, bailing out"
#        exit 1
#    fi
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
curl -H "Authorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/channels/$CHANNEL/videos?fields=name,link" -s \
    | jq -r '.data[]|.name,.link' \
         > ${TMP_FILE}

cat ${TMP_FILE} | while read apa; \
    do if [[ $((i++%2==1)) -eq 0 ]]; \
       then name=$apa; \
       else URL=$apa;echo "<a href=\"$URL\">$name</a>"; \
       fi; \
    done

cat ${TMP_FILE} | while read apa; \
    do if [[ $((i++%2==1)) -eq 0 ]]; \
       then name=$apa; \
       else URL=$apa;echo "* [$URL $name]"; \
       fi; \
    done
