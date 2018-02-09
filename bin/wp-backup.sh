#!/bin/bash


DATE=$(date '+%Y%m%d')
LOG_FILE=logs/wp-backup-$DATE.log

#DEBUG=true

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

get_index()
{
    WP_FILE=$1
    rm -f $WP_NAME.html
    log "Getting index file ($WP_FILE => $WP_NAME)"
    wget -q $WP_FILE -O $WP_NAME.html
    exit_on_error $?
}

extract_links()
{
    log "extracting links"
    LINKS=$(cat $WP_NAME.html | sed "s,[ =>'],\n,g" | grep http | grep $WP_NAME.wordpress.com/20[0-9]*/[0-5][0-9]/$)
    exit_on_error $?
}

handle_archive_file()
{
    log "    handling archive file :$1"
    DATE_PART=$(echo $1 | sed 's,[/],\n,g' | tail -3 | head -2 | tr '\n' '-' | sed 's,-$,,g')
    A_FILE=$WP_NAME-$DATE_PART".html"
    if [ ! -f $A_FILE ] || [ "$(file $A_FILE | grep HTML | wc -l)" = "0" ]
    then
        log "    downloading to file $A_FILE"
        wget -q $1 -O $A_FILE
        exit_on_error $?
    else
        log "    ignoring file, already downloaded"
    fi

    if [ "$WP_NAME" = "programmingpedagogy" ]
    then
        A_LINKS=$(cat $A_FILE | grep ".entry-header" | sed 's,[ <>"=],\n,g' | grep http)
    else
        A_LINKS=$(cat $A_FILE | grep -A 2 "\"post-" | sed 's,[ <>"=],\n,g' | grep http)
    fi

    for alink in $A_LINKS
    do
        log "      checking blog posts: $alink"
        afile=$WP_NAME-$DATE_PART-$(echo $alink | sed 's,[/],\n,g' | tail -2 | head -1)
        if [ ! -f $afile ] || [ "$(file $afile | grep HTML | wc -l)" = "0" ]
        then
            log "      downloading to file: $afile.html"
            wget -q $alink -O $afile.html
            exit_on_error $?
        else
            log "      ignoring file, already downloaded"
        fi
    done
}

handle_archive_files()
{
    for link in $LINKS
    do
        log " archive file: $link"
        handle_archive_file $link
    done
}

close()
{
    log "We're done, bye for now"
}

handle_wp()
{
    WP_NAME=$1
    WP_INDEX=https://$WP_NAME.wordpress.com/
    get_index $WP_INDEX

    extract_links 
    handle_archive_files
}

init
handle_wp programmeringspedagogik 
handle_wp programmingpedagogy


