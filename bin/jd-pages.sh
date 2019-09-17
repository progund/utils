#!/bin/bash

PAGE_URL=$1
FIRST_DATE=$2
BASE_DIR=/tmp/jd-books
DATE=$(date '+%Y%m%d')

if [ "$PAGE_URL" = "" ]
then
    echo "Missing argument(s)"
    exit 1
fi

if [ "$FIRST_DATE" = "" ]
then
    FIRST_DATE=$DATE
fi

if [ ! -d $BASE_DIR ]
then
    mkdir -p $BASE_DIR
fi

htmldoc --size A4 "$PAGE_URL" --outfile $BASE_DIR/wiki.pdf 2>&1 /dev/null >  /dev/null 2>&1

pdfinfo $BASE_DIR/wiki.pdf 2>&1 | grep Pages | awk '{print $2}'
