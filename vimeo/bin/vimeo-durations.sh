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
TODAY_DUR=/tmp/vimeo-durations-${TODAY}.txt

do_dur()
{
    LAST_PAGE=$(curl -H "Authorization: Bearer $VIMEO_BEARER" 'https://api.vimeo.com/me/videos?fields=link&per_page=100' -s|grep last|rev|cut -d '=' -f1|tr -d '"')
    TOTAL_DURATION=0
    DURATION=0
    for i in $(seq 1 $LAST_PAGE)
    do
        for DURATION in $(curl -H "Authorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/me/videos?fields=duration&per_page=100&page=$i" -s | grep '"duration'|cut -d ':' -f2 )
        do
            TOTAL_DURATION=$(( $TOTAL_DURATION + $DURATION ))
        done
    done
    # Print how many videos we have
    NUM_VIDS=$(curl -H "Authorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/me/videos?per_page=1&fields=total" -s|grep '"total"'|cut -d ':' -f2|tr -d ',' | sed 's,[ ]*,,g')
    AVG_DUR=$(( TOTAL_DURATION / NUM_VIDS ))
    echo "Videos"
    echo "-----------------"
    echo "Videos: $NUM_VIDS" 
    echo 
    echo "Total duration:"
    echo "-----------------"
    echo "$TOTAL_DURATION seconds"
    eval "echo $(date -ud "@$TOTAL_DURATION" +'$((%s/3600/24)) days %H hours %M minutes %S seconds')"    
    echo
    echo "Average duration"
    echo "-----------------"
    echo "$AVG_DUR seconds"
    eval "echo $(date -ud "@$AVG_DUR" +'$((%s/60)) minutes %S seconds')"
}

if [ ! -f $TODAY_DUR ]  || [ "$1" = "-f" ]
then
    do_dur > $TODAY_DUR
fi 


#echo $TODAY_DUR
cat  $TODAY_DUR
exit

