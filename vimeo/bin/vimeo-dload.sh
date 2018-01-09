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

#VIDEO_LINK_ID=$(GET https://player.vimeo.com/video/$VIDEO_ID/config | jq '.request.files.dash.streams|sort_by(.quality|gsub("p";"")|tonumber)|reverse[0].id')
#echo $VIDEO_LINK_ID
GET https://player.vimeo.com/video/$VIDEO_ID/config | jq '.request.files.dash.streams|sort_by(.quality|gsub("p";"")|tonumber)|reverse'
GET https://player.vimeo.com/video/$VIDEO_ID/config|jq '.request.files.progressive[]|.url'
    #| grep $VIDEO_LINK_ID

#|jq '.request.files.dash.streams|=sort_by(.stream)'
#VIDEO_TITLE=$(GET https://player.vimeo.com/video/$VIDEO_ID/config|jq '.video.title')

#VID_URL=$(get_list_of_videos | sort -n | tail -1 | awk ' {print $2}' | sed 's/[",]*//g')

#curl $VID_URL -o $VIDEO_ID.mp4


#250121892
