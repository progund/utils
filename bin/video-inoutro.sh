#!/bin/bash

LECTURE=$1
INTRO=$(dirname $0)/../video/jd-intro.webm
OUTRO=$(dirname $0)/../video/jd-outro.webm

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

mkvmerge -o jd-${LECTURE}  ${INTRO} + $LECTURE + ${OUTRO} ;
