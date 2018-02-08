#!/bin/bash

RSS_FILE=juneday.rss

DATE=$(date '+%Y%m%d')
LOG_FILE=logs/podbean-$DATE.log



init()
{
    mkdir -p logs
}

log()
{
    if [ "$DEBUG" = "true" ]
    then
        echo "$*"
    fi
    echo "[$(date)] $*" >> $LOG_FILE
}


exit_on_error()
{
    if [ $1 -ne 0 ]
    then
        log "Woops, something went wrong. Bailing out"
        exit $1
    fi
}

get_rss()
{
    log "Getting RSS file"
    wget -q http://juneday.podbean.com/feed/ -O $RSS_FILE
    exit_on_error $?
}

extract_links()
{
    log "extracting links"
    LINKS=$(cat $RSS_FILE | grep http://juneday.podbean.com/e | grep link | sed 's,[<>],\n,g' | grep http)
    exit_on_error $?
}

download_links()
{
    for link in $LINKS
    do
        log "Link: $link"
        OFILE="$(echo $link | tr '/' '\n' | tail -2 | head -1)".html
        log "  html file: $OFILE"
        if [ ! -f $OFILE ] || [ $(file $OFILE | grep HTML | wc -l) -eq 0 ]
        then
            log "    - downloading"
            wget -q $link -O $OFILE
            exit_on_error $?
        else
            log "    - already downloaded"
        fi
        MP3_URL=$(grep mp3 $OFILE | sed 's,[<> ],\n,g' | grep mp3 | grep data-uri | sed -e 's,data-uri=,,g' -e 's,",,g')
        MP3_FILE=$(echo $MP3_URL | sed 's,/,\n,g' | tail -1)
        log "  mp3: $MP3_FILE"
        if [ ! -f $MP3_FILE ] || [ $(file $MP3_FILE | grep -i audio | wc -l) -eq 0 ]
        then
            log "    - downloading"
            wget -q $MP3_URL -O $MP3_FILE
            exit_on_error $?
        else
            log "    - already downloaded"
        fi
    done
}

close()
{
    log "We're done, bye for now"
}

init
get_rss
extract_links
download_links
close



