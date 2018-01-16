#!/bin/bash

PROG_NAME=$(basename $0)

usage()
{
    echo "NAME"
    echo "  $PROG_NAME - download a video from vimeo.com"
    echo ""
    echo "SYNOPSIS"
    echo "  $PROG_NAME <vimeo-id>"
    echo ""
    echo "DESCRIPTION"
    echo "  Download a video, given a vimeo video id, with the best available"
    echo "  quality. The name of the resulting file is taken from the video "
    echo "  title at vimeo. Download is NOT done if the video already has been downloaded."
    echo ""
    echo "OPTIONS"
    echo "  --help, -h - prints this help text"
    echo ""
    echo "RETURN VALUES"
    echo "  0 - success"
    echo "  1 - video already downloaded"
    echo "  2 or higher - indicates error... sorry no more info :("
    echo ""
    echo "ENVIRONMENT VARIABLES"
    echo "  DEBUG - enables debug printout"
    echo ""
    echo "EXAMPLES"
    echo ""
    echo "  $PROG_NAME 250121892"
    echo ""
    echo "  DEBUG=true $PROG_NAME 250121892"
    echo 
    
}

while [ "$1" != "" ]
do
    case "$1" in
        "--help"|"-h")
            usage
            exit 0
            ;;                       
        "--destination-dir"|"-d")
            DEST_DIR=$2/
            shift
            ;;
        *)
            break
            ;;
    esac
    shift
done

if [ "$1" = "" ]
then
    echo "Mising argument"
    usage
    exit 1
fi
VIDEO_ID=$1


debug()
{
    if [ "$DEBUG" = "true" ]
    then
        echo $*
    fi
}

get_list_of_videos()
{
    GET https://player.vimeo.com/video/$VIDEO_ID/config|jq '.'\
        | grep -B5 'mp4?' \
        | grep -e url -e width \
        | while (true) ; do \
        read WIDTH; read URL ; \
        WIDTH=$(echo $WIDTH | awk ' { print $2}' | sed 's/[,:]*//g') ;\
        VIDEO_URL=$(echo $URL | awk '{ print $2}');\
        echo "$WIDTH  $VIDEO_URL"; \
        if [ "$WIDTH" = "" ] ; then break ; fi ; \
        done ; 
    RET=$?
    if [ $RET -ne 0 ]
    then
        exit 2
    fi
}

#VIDEO_LINK_ID=$(GET https://player.vimeo.com/video/$VIDEO_ID/config | jq '.request.files.dash.streams|sort_by(.quality|gsub("p";"")|tonumber)|reverse[0].id')
#echo $VIDEO_LINK_ID
VIDEO_LINK_INFO=$(GET https://player.vimeo.com/video/$VIDEO_ID/config \
                      | jq '.request.files.dash.streams|sort_by(.quality|gsub("p";"")|tonumber)|reverse')
RET=$?
if [ $RET -ne 0 ]
then
    echo "*** ERROR ***"
    echo "Failed downloding and analysing https://player.vimeo.com/video/$VIDEO_ID/config"
    echo "Return value: $RET"
    exit 2
fi

VIDEO_LINK_IDS=$(echo $VIDEO_LINK_INFO | jq '.' \
    | grep id \
    | awk ' { print $2}' \
    | sed 's/,//g')
debug "-------"

VIDEO_LINK_URLS=$(GET https://player.vimeo.com/video/$VIDEO_ID/config|jq '.request.files.progressive[]|.url')
RET=$?
if [ $RET -ne 0 ]
then
    echo "*** ERROR ***"
    echo "Failed getting and analysing urls https://player.vimeo.com/video/$VIDEO_ID/config"
    echo "Return value: $RET"
    exit 2
fi

DLOAD_URL=""
for vli in $VIDEO_LINK_IDS
do
    debug "Trying vli: $vli"
    if [ "$DLOAD_URL" != "" ]
    then
        break
    fi
    for vlu in $VIDEO_LINK_URLS
    do
        debug "  -- trying url: $vlu"
        echo $vlu | grep $vli  >/dev/null 2>/dev/null 
        RET=$?
        debug "$RET"
        if [ $RET -eq 0 ]
        then
            DLOAD_URL=$(echo $vlu | sed -e 's,",,g' -e 's,"$,,g')
            break
        fi
    done
done
debug "----------------------------------------"
debug "Using download url: $DLOAD_URL"
debug "----------------------------------------"
VIDEO_TITLE=$(GET https://player.vimeo.com/video/$VIDEO_ID/config|jq '.video.title' | sed -e 's,[ /],_,g' -e 's,",,g')
RET=$?
if [ $RET -ne 0 ]
then
    echo "*** ERROR ***"
    echo "Failed getting title from https://player.vimeo.com/video/$VIDEO_ID/config"
    echo "Return value: $RET"
    exit 2
fi

debug "=========================="
debug "VIDEO_LINK_URLS: $VIDEO_LINK_URLS"
debug "----------------------------------------"
debug "VIDEO_LINK_INFO: $VIDEO_LINK_INFO"
debug "----------------------------------------"
debug "VIDEO_LINK_IDS: $VIDEO_LINK_IDS"
debug "=========================="

if [ -f $DEST_DIR$VIDEO_TITLE.mp4 ]
then
    echo "    already downloaded, skipping ($DEST_DIR$VIDEO_TITLE.mp4)"
    exit 1
else
    echo "    downloading $DLOAD_URL" 
    curl -s $DLOAD_URL -o $DEST_DIR$VIDEO_TITLE.mp4
    RET=$?
    if [ $RET -ne 0 ]
    then
        echo "*** ERROR ***"
        echo "Failed downloading video"
        echo "  from $DLOAD_URL"
        echo "  to   $DEST_DIR$VIDEO_TITLE.mp4"
        echo "Return value: $RET"
        exit 2
    fi
    echo "      $VIDEO_TITLE.mp4 to $DEST_DIR"
fi

exit 0
