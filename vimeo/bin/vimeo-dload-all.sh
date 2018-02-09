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

# set this to NOT 0 to force download. otherwise trying to use stored JSON files
FORCE_DOWNLOAD=0


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
        "--force"|"-f")
            FORCE_DOWNLOAD=1
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

check_vimeo_request_limit()
{
    VFILE=$1
    VIM_ERROR=$(cat $VFILE | grep -i error | grep -i "too many api" | wc -l)
    echo -n "    Checking file \"$VFILE\" for errors:"
    if [ $VIM_ERROR -ne 0 ]
    then
        echo "*** VIMEO REQUEST ERROR ***   file contained Too may requests info. Returning error ($VIM_ERROR)"
    else
        echo " OK "
    fi
    return $VIM_ERROR
}

dload()
{
    URL="$1"
    OFILE="$2"

    #
    # if file contained error text, remove it
    #
    if [ -f $OFILE ]
    then
        check_vimeo_request_limit $OFILE
        if [ $? -ne 0 ]
        then
            rm $OFILE
        fi
    fi
    
    
    if [ ! -f $OFILE ] || [ $FORCE_DOWNLOAD -gt 0 ]
    then
        echo "    Downloading url \"$URL\" (----> \"$OFILE\")"
        curl -s -H "Authorization: Bearer ${VIMEO_BEARER}" "$URL" > $OFILE
        RET=$?
        if [ $RET -ne 0 ]
        then
            echo "*** ERROR ***"
            echo "Failed downloading \"$*\""
            echo "Return value: $RET"
            exit 2
        fi

        #
        # if file contained error text, remove it and exit
        #
        if [ -f $OFILE ]
        then
            check_vimeo_request_limit $OFILE
            RET=$?
            echo "    status after downloading of file $OFILE:   $RET"
            if [ $RET -ne 0 ]
            then
                echo "    -- uh oh, too many requests problem, exit"
                rm $OFILE
                exit 2
            else
                echo "    -- all went fine "
            fi
        fi

    else
        echo "    Skipping download of \"$URL\" (----> \"$OFILE\")"
    fi
}

VIMEO_CHANNELS=$($SCRIPTDIR/vimeo-channels.sh)
DLOAD_CNT=0
CHANNEL_JSON=$DEST_DIR/channel.json
CHANNELS_JSON=$DEST_DIR/channels.json

dload "https://api.vimeo.com/me/channels?per_page=100&fields=uri,name&page=1" "$CHANNELS_JSON"

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
    
    dload "https://api.vimeo.com/channels/$channel" "$CHANNEL_JSON"

    VIDEOS_JSON=$CH_DIR/videos.json
    dload "https://api.vimeo.com/channels/$channel/videos" "$VIDEOS_JSON"

    VIDEOS=$(cat $VIDEOS_JSON | jq '.data[].uri' | sed 's,",,g')
    RET=$?
    echo "    jq parsing went: $RET"
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

        $SCRIPTDIR/vimeo-dload.sh --destination-dir $CH_DIR/videos/$video/ $video "mp4"
        RET=$?
        if [ $RET -eq 0 ]
        then
            dload "https://api.vimeo.com/videos/$video"  "$CH_DIR/videos/$video/video.json"
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
