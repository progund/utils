#!/bin/bash

SCRIPTDIR=$(dirname $0)
# file with Beaerer defined in variable VIMEO_BEARER
SETTINGS=$SCRIPTDIR/../../../utils-private/etc/vimeo.rc
if [ ! -f ${SETTINGS} ]
then
    echo "Can't find file $SETTINGS"
    echo "failed, bailing out"
else
    . ${SETTINGS}
fi

#
# default values
#
DEST_DIR=$(pwd)/vimeo/channels
DLOAD_LIMIT=20


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
    echo "  --loop -  loops until all videos are downloaded. Beware, "
    echo "            vimeo will kick you out. Make sure to use a huge delay."
    echo ""
    echo "  --delay <sec> - delay (in seconds) between downloads when looping."
    echo "            Defaults to 0"
    echo ""
    echo ""
    echo "EXAMPLES"
    echo ""
    echo "  $PROG_NAME --limit-download 10 --destination-dir /var/ww/html"
    echo "     downloads at most 10 videos to /var/ww/html"
    echo "     put this in a cron job and you'll have a backup (some day)"
    echo "     of all your videos"
    echo ""
    echo "  $PROG_NAME --limit-download 10 --destination-dir /var/ww/html --loop --delay 3600"
    echo "     downloads at most 10 videos to /var/ww/html,"
    echo "     sleep for one hour and continues until done downloading all videos."
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
        "--delay")
            DELAY=$2
            shift
            ;;
        "--loop")
            LOOP=true
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

VIMEO_CHANNELS=$($SCRIPTDIR/vimeo-channels.sh)
DLOAD_CNT=0

for channel in $VIMEO_CHANNELS
do
    echo "Channel: $channel"
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
        echo "  Video: $vid"

        if [ $DLOAD_LIMIT -gt 0 ] && [ $DLOAD_CNT -ge $DLOAD_LIMIT ]
        then
            echo "Maximum number of downloads ($DLOAD_LIMIT) reached."
            if [ "$LOOP" = "true" ]
            then
                echo " ... will sleep for $DELAY seconds"
                sleep $DELAY
            else
                echo "Leaving, thanks for now"
                exit 0
            fi
        fi


        video=$(echo $vid | sed 's,/, ,g' | awk ' { print $2} ')
#        echo "VIDEOS | $vid | $video"
        mkdir -p $CH_DIR/videos/$video
        dload https://api.vimeo.com/videos/$video > $CH_DIR/videos/$video/video.json
        $SCRIPTDIR/vimeo-dload.sh --destination-dir $CH_DIR/videos/$video/ $video
        RET=$?
        if [ $RET -eq 0 ]
        then
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
