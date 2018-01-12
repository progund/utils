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

#
# default values
#
DEST_DIR=$(pwd)/vimeo/channels
DLOAD_LIMIT=-1


usage()
{
    PROG_NAME=$(basename $0)
    echo "NAME"
    echo "  $PROG_NAME - downloads (all or limited) videos from Vimeo"
    echo ""
    echo "SYNOPSIS"
    echo "  $PROG_NAME [OPTION]"
    echo ""
    echo "DESCRIPTION"
    echo "  This script finds all the channels at vimeo.   "
    echo "  For each found channel:" 
    echo "    * download meta information about the channel"
    echo "    * find the videos (in the channel"
    echo "    * For each found video:"
    echo "      * download meta information"
    echo "      * download (if not already downloaded) video"
    echo ""
    echo "OPTION"
    echo ""
    echo "  --destination-dir <dir>, -d <dir> - stores files in <dir>"
    echo ""
    echo "  --limit <nr>, -l <nr> - limits the number of downloads to nr."
    echo "            in case vimeo prevents many downloads. Only successful download"
    echo "            counts so running this script with a limit (>0) will eventually"
    echo "            end up having downloaded all videos."
    echo ""
    echo "EXAMPLES"
    echo ""
    echo "  $PROG_NAME --limit-download 10 --destination-dir /var/ww/html"
    echo "     downloads at most 10 videos to /var/ww/html"
    echo "     put this in a cron job and you'll have a backup (some day)"
    echo "     of all your videos"
    echo ""
}

while [ "$1" != "" ]
do
    case "$1" in
        "--help"|"-h")
            usage
            exit 0
            ;;
        "--limit-download"|"-l")
            DLOAD_LIMIT=$2
            shift
            ;;
        "--destination-dir"|"-d")
            DEST_DIR=$2
            shift
            mkdir -p $DEST_DIR
            if [ $? -ne 0 ]
            then
                echo "Failed creating dir \"$DEST_DIR\""
                exit 1
            fi
            ;;
        *)
            echo "SYNTAX ERROR ($1)"
            exit 2
            ;;
    esac
    shift
done


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

#VIMEO_CHANNELS=$($SCRIPTDIR/vimeo-channels.sh)
DLOAD_CNT=0
# set this to NOT 0 to force download. otherwise trying to use stored JSON files
FORCE_DOWNLOAD=0
CHANNEL_JSON=$DEST_DIR/channel.json

if [ ! -f $CHANNELS_JSON ] || [ $FORCE_DOWNLOAD -gt 0 ]
then
    echo "    downloading... channels json"
    curl -H "Authorization: Bearer ${VIMEO_BEARER}" "https://api.vimeo.com/me/channels?per_page=100&fields=uri,name&page=1" > $CHANNELS_JSON
fi

VIMEO_CHANNELS=$(cat $CHANNELS_JSON \
        | grep "uri" \
        | awk '{ print $2 }' \
        | sed -e 's,",,g' -e 's,\/channels\/,,g' -e 's/,//g'\
        | grep -v "per_page=")

for channel in $VIMEO_CHANNELS
do
    echo "Channel: $channel"
    CH_DIR=$DEST_DIR/$channel
    mkdir -p $CH_DIR/videos

    CHANNEL_JSON=$CH_DIR/channel.json
    
    if [ ! -f $CHANNEL_JSON ] || [ $FORCE_DOWNLOAD -gt 0 ]
    then
        echo "    downloading... channel json"
        dload "https://api.vimeo.com/channels/$channel" > $CHANNEL_JSON
    fi

    VIDEOS_JSON=$CH_DIR/videos.json
    if [ ! -f $VIDEOS_JSON ] || [ $FORCE_DOWNLOAD -gt 0 ]
    then
        echo "    downloading... videos json"
        dload "https://api.vimeo.com/channels/$channel/videos" > $VIDEOS_JSON
    fi

    VIDEOS=$(cat $VIDEOS_JSON | jq '.data[].uri' | sed 's,",,g')
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
        echo "  Video: $vid"

        if [ $DLOAD_LIMIT -gt 0 ] && [ $DLOAD_CNT -ge $DLOAD_LIMIT ]
        then
            echo "Maximum number of downloads ($DLOAD_LIMIT) reached. Leaving, thanks for now"
            exit 0
        fi

        video=$(echo $vid | sed 's,/, ,g' | awk ' { print $2} ')
#        echo "VIDEOS | $vid | $video"
        mkdir -p $CH_DIR/videos/$video
        $SCRIPTDIR/vimeo-dload.sh --destination-dir $CH_DIR/videos/$video/ $video
        RET=$?
        if [ $RET -eq 0 ]
        then
            dload https://api.vimeo.com/videos/$video > $CH_DIR/videos/$video/video.json
            DLOAD_CNT=$(( $DLOAD_CNT + 1 ))            
            echo "    $DLOAD_CNT downloaded so far, limit: $DLOAD_LIMIT"
        elif [ $RET -eq 1 ]
        then
            echo "    already downloaded, not counting as download"
        elif [ $RET -ne 0 ]
        then
            echo "*** ERROR ***"
            echo "Failed downlod video: $video"
            echo "Return value: $RET"
            exit 2
        fi
    done

done
