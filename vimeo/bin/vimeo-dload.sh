#!/bin/bash

VIDEO_ID=$1
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
    echo "  title at vimeo"
    echo ""
    echo "OPTIONS"
    echo "  --help, -h - prints this help text"
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

if [ "$1" = "" ]
then
    echo "Mising argument"
    usage
    exit 1
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]
then
    usage
    exit 0
fi


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
}

#VIDEO_LINK_ID=$(GET https://player.vimeo.com/video/$VIDEO_ID/config | jq '.request.files.dash.streams|sort_by(.quality|gsub("p";"")|tonumber)|reverse[0].id')
#echo $VIDEO_LINK_ID
VIDEO_LINK_INFO=$(GET https://player.vimeo.com/video/$VIDEO_ID/config \
                      | jq '.request.files.dash.streams|sort_by(.quality|gsub("p";"")|tonumber)|reverse')

VIDEO_LINK_IDS=$(echo $VIDEO_LINK_INFO | jq '.' \
    | grep id \
    | awk ' { print $2}' \
    | sed 's/,//g')
debug "-------"
VIDEO_LINK_URLS=$(GET https://player.vimeo.com/video/$VIDEO_ID/config|jq '.request.files.progressive[]|.url')
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
        echo $vlu | grep $vli 
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
VIDEO_TITLE=$(GET https://player.vimeo.com/video/$VIDEO_ID/config|jq '.video.title' | sed -e 's, ,_,g' -e 's,",,g')

debug "=========================="
debug "VIDEO_LINK_URLS: $VIDEO_LINK_URLS"
debug "----------------------------------------"
debug "VIDEO_LINK_INFO: $VIDEO_LINK_INFO"
debug "----------------------------------------"
debug "VIDEO_LINK_IDS: $VIDEO_LINK_IDS"
debug "=========================="

curl $DLOAD_URL -o $VIDEO_TITLE.mp4
echo "$VIDEO_TITLE.mp4"



#250121892
