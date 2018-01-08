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
FILENAME=$(basename $LECTURE)
SUFF="${FILENAME##*.}"


INTRO=$(dirname $0)/../../utils-blobs/video/jd-intro-2560-1600.$SUFF
OUTRO=$(dirname $0)/../../utils-blobs/video/jd-outro-2560-1600.$SUFF

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

#mkvmerge -o jd-${LECTURE}  ${INTRO} + $LECTURE + ${OUTRO} ;

VIDS="$LECTURE"
if [ "$USE_INTRO" = "true" ]
then
    echo "Using INTRO"
    VIDS=" ${INTRO} + $VIDS"
fi
if [ "$USE_OUTRO" = "true" ]
then
    echo "Using OUTRO"
    VIDS=" $VIDS + $OUTRO"
fi

echo "$USE_INTRO | $USE_OUTRO | $VIDS"
mkvmerge -o jd-${LECTURE}  ${VIDS}
