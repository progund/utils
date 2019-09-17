#!/bin/bash

FIRST_DATE=$1
SECOND_DATE=$2
BASE_DIR=/tmp/jd-books
DATE=$(date '+%Y%m%d')
BASE_URL=http://rameau.sandklef.com/junedaywiki-stats/

if [ "$FIRST_DATE" = "" ]
then
    FIRST_DATE=$DATE
    SECOND_DATE=""
fi


if [ ! -d $BASE_DIR ]
then
    mkdir -p $BASE_DIR
fi


FIRST_JSON="${BASE_DIR}/$FIRST_DATE.json"
SECOND_JSON="${BASE_DIR}/$SECOND_DATE.json"

download_json()
{
    FILE_TO_SAVE="${BASE_DIR}/$1.json"
    if [ ! -f "$FILE_TO_SAVE" ]
    then
        curl -s -o "$FILE_TO_SAVE" "$BASE_URL/$1/jd-stats.json"
    fi
}

download_json "$FIRST_DATE"

single_date()
{
    echo "Books statistics from ($FIRST_DATE)"
    echo
    printf " %-40s %5s\n" "Book " "Pages"
    echo "--------------------------------------------------"
    jq '.books[]|.title,.pages' "$FIRST_JSON" | sed 's,",,g' | while (true) ; do
        read -r NAME
	read -r PAGES
        if [ "$PAGES" = "" ] ; then break ; fi
        printf " %-40s %5d\n" "$NAME:" "$PAGES"
    done | rev | sort -nr | rev
}

two_dates()
{
    echo "Books statistics from ($FIRST_DATE - $SECOND_DATE)"
    echo
    printf " %-40s %5s %5s %s\n" "Book " "Pages" "Pages" "diff"
    echo "-------------------------------------------------------------------"
    jq '.books[]|.title' $SECOND_JSON | sed 's,\",,g' | while read -r BOOK_TITLE
    do
        FIRST_PAGES=$(jq --raw-output ".books[] | select(.title==\"$BOOK_TITLE\") | .pages" "$FIRST_JSON")
        SECOND_PAGES=$(jq --raw-output ".books[] | select(.title==\"$BOOK_TITLE\") | .pages" "$SECOND_JSON")
        if [ "$FIRST_PAGES" = "" ]
        then
            FIRST_PAGES=0
        fi
        printf " %-40s %5s %5s %s\n" "$BOOK_TITLE" "$FIRST_PAGES"  "$SECOND_PAGES"  $(( SECOND_PAGES - FIRST_PAGES))
    done | rev | sort -nr | rev
}



if [ "$SECOND_DATE" = "" ]
then
    single_date
else
    download_json "$SECOND_DATE"
    two_dates
fi
