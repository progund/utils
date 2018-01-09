#!/bin/bash

VIDEO_ID=$1

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

VID_URL=$(get_list_of_videos | sort -n | tail -1 | awk ' {print $2}' | sed 's/[",]*//g')

curl $VID_URL -o $VIDEO_ID.mp4

#250121892
