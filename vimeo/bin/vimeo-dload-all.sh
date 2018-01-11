#!/bin/bash

SCRIPTDIR=$(dirname $0)
# file with Beaerer defined in variable VIMEO_BEARER
SETTINGS=$SCRIPTDIR/../../../utils-private/etc/vimeo.rc
if [ ! -f ${SETTINGS} ]
then
    echo "Can't find file $SETTINGS"
        echo "failed, bailing out"
fi
. ${SETTINGS}
DEST_DIR=$(pwd)/vimeo/channels

dload()
{
    curl -s -H "Authorization: Bearer ${VIMEO_BEARER}" "$*"
    RET=$?
    if [ $RET -ne 0 ]
    then
        echo "*** ERROR ***"
        echo "Failed downloading \"$*\""
        echo "Return value: $RET"
        exit 2
    fi
}

VIMEO_CHANNELS=$($SCRIPTDIR/vimeo-channels.sh)
for channel in $VIMEO_CHANNELS
do
#    echo $channel
    CH_DIR=$DEST_DIR/$channel
    mkdir -p $CH_DIR/videos

    dload "https://api.vimeo.com/channels/$channel" > $CH_DIR/channel.json
    dload "https://api.vimeo.com/channels/$channel/videos" > $CH_DIR/videos.json
    VIDEOS=$(cat $CH_DIR/videos.json | jq '.data[].uri' | sed 's,",,g')
    RET=$?
    if [ $RET -ne 0 ]
    then
        echo "*** ERROR ***"
        echo "Failed extracting videos from $CH_DIR/videos.json"
        echo "Return value: $RET"
        exit 2
    fi
    
 #   echo "VIDEOS: $VIDEOS"
    for vid in $VIDEOS
    do
        video=$(echo $vid | sed 's,/, ,g' | awk ' { print $2} ')
#        echo "VIDEOS | $vid | $video"
        mkdir -p $CH_DIR/videos/$video
        dload https://api.vimeo.com/videos/$video > $CH_DIR/videos/$video/video.json
        $SCRIPTDIR/vimeo-dload.sh --destination-dir $CH_DIR/videos/$video/ $video
        RET=$?
        if [ $RET -ne 0 ]
        then
            echo "*** ERROR ***"
            echo "Failed downlod video: $video"
            echo "Return value: $RET"
            exit 2
        fi
    done

    #remove this
    exit
done
