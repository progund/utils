#!/bin/bash


USE_OUTRO=true
USE_INTRO=true
if [ "$1" = "--only-intro" ] || [ "$1" = "-oi" ]
then
    USE_OUTRO=false
    shift
elif [ "$1" = "--only-outro" ] || [ "$1" = "-oo" ]
then
    USE_INTRO=false
    shift
fi

LECTURE=$1
INTRO=$(dirname $0)/../../utils-blobs/sounds/jundey-pod-intro-eng.mp3
OUTRO=$(dirname $0)/../../utils-blobs/sounds/jundey-pod-outtro-eng.mp3


convert_to_mp3()
{
    
    if [ "$(file $1 | grep -i mp4 | wc -l)" = "1" ]
    then
        echo "Converting mp4 file"
        echo "Backup can be found in `pwd`/backup"
        file $1
        mkdir -p backup/
        cp $1 backup/
        MP4_NAME=$(echo $1 | sed 's,\.mp3,\.mp4,g')
        MP3_NAME=$1
        
        mv $MP3_NAME $MP4_NAME
        ffmpeg -i $MP4_NAME $MP3_NAME 
        file $1
    fi
}

exit_if_missing()
{
    if [ ! -f "$1" ]
    then
        echo "$1 missing or not a file"
        exit 1
    fi
}

if [ "$LECTURE" = "" ]
then
    echo "Missing lecture name"
    exit 2
fi

exit_if_missing $INTRO
exit_if_missing $OUTRO
exit_if_missing $LECTURE

convert_to_mp3 $LECTURE

AUDIOS="$LECTURE"
if [ "$USE_INTRO" = "true" ]
then
    echo "Using INTRO"
    AUDIOS="${INTRO}|$AUDIOS"
fi
if [ "$USE_OUTRO" = "true" ]
then
    echo "Using OUTRO"
    AUDIOS="$AUDIOS|$OUTRO"
fi

echo "$USE_INTRO | $USE_OUTRO | $AUDIOS"

#mp3wrap jd-${LECTURE} ${AUDIOS} 
ffmpeg -i "concat:${AUDIOS}" -acodec libmp3lame jd-${LECTURE}
#mkvmerge -o jd-${LECTURE}  ${AUDIOS}
#id3cp ${LECTURE} jd-${LECTURE}
