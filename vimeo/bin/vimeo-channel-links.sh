#/bin/bash

SCRIPTDIR=$(dirname $0)
# file with Beaerer defined in variable VIMEO_BEARER
SETTINGS=$SCRIPTDIR/../../../utils-private/etc/vimeo.rc
if [ ! -f ${SETTINGS} ]
then
    echo "Can't find file $SETTINGS"
#    echo "Trying to clone repo"
#    git clone git@github.com:progund/utils-private.git
#    RET=$?
#    cd -
#    if [ $RET -ne 0 ] || [ ! -f ${SETTINGS} ]
#    then
        echo "failed, bailing out"
        exit 1
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
CH_NAME=$(curl -H A"uthorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/channels/$CHANNEL?fields=name"| jq '.name' | sed 's,",,g')
curl -H "Authorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/channels/$CHANNEL/videos?fields=name,link&sort=manual" -s \
    | jq -r '.data[]|.name,.link' \
         > ${TMP_FILE}

echo
echo
echo "HTML"
echo
cat ${TMP_FILE} | while read apa; \
    do if [[ $((i++%2==1)) -eq 0 ]]; \
       then name=$apa; \
       else URL=$apa;echo "<a href=\"$URL\">$name</a>"; \
       fi; \
    done

echo
echo
echo "Old channel fomat"
echo
echo "[https://vimeo.com/channels/$CHANNEL $CH_NAME]"
cat ${TMP_FILE} | while read apa; \
    do if [[ $((i++%2==1)) -eq 0 ]]; \
       then name=$apa; \
       else URL=$apa;echo "* [$URL $name]"; \
       fi; \
    done


current_channel_format()
{
    echo -n " [https://vimeo.com/couchmode/channels/$CHANNEL $CH_NAME (Playlist)] "
    cat ${TMP_FILE} | while read apa; \
        do if [[ $((i++%2==1)) -eq 0 ]]; \
           then name=$apa; \
           else
               URL=$apa;
               echo -n " | [$URL $name] "; \
                   fi; \
                   done
    echo
}

echo
echo
echo "Current channel fomat (stored in primary clipboard)"
echo
ch_format=$(current_channel_format)
echo $ch_format | xclip -i -selection clipboard
echo $ch_format

