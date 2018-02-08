#!/bin/bash

DEST_DIR=juneday-pod-backup
RSS_FILE=juneday.rss

mkdir -p $DEST_DIR
cd $DEST_DIR

log()
{
    }


exit_on_error()
{
    if [ $1 -ne 0 ]
    then
        echo "Woops, something went wrong. Bailing out"
        exit $1
    fi
}

wget http://juneday.podbean.com/feed/ -O $RSS_FILE
exit_on_error $?

LINKS=$(cat $RSS_FILE | grep http://juneday.podbean.com/e | grep link | sed 's,[<>],\n,g' | grep http)
exit_on_error $?

for link in $LINKS
do
    echo "Link: $link"
    OFILE="$(echo $link | tr '/' '\n' | tail -2 | head -1)".html
    echo "  html file: $OFILE"
    if [ ! -f $OFILE ] || [ $(file $OFILE | grep HTML | wc -l) -eq 0 ]
    then
        echo "    - downloading"
        wget $link -O $OFILE
        exit_on_error $?
    else
        echo "    - already downloaded"
    fi
    MP3_URL=$(grep mp3 $OFILE | sed 's,[<> ],\n,g' | grep mp3 | grep data-uri | sed -e 's,data-uri=,,g' -e 's,",,g')
    MP3_FILE=$(echo $MP3_URL | sed 's,/,\n,g' | tail -1)
    echo "  mp3: $MP3_FILE"
    if [ ! -f $MP3_FILE ] || [ $(file $MP3_FILE | grep -i audio | wc -l) -eq 0 ]
    then
        echo "    - downloading"
        wget $MP3_URL -O $MP3_FILE
        exit_on_error $?
    else
        echo "    - already downloaded"
    fi
done

