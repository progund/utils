#!/bin/bash

DATE=$(date '+%Y%m%d')

JD_STAT_URL=http://rameau.sandklef.com/junedaywiki-stats
JD_STAT_JSON=jd-complete.json

while [ "$1" != "" ]
do
    case "$1" in
        "--date")
            DATE=$2
            shift
            ;;
        "--books"|"-b")
            BOOKS=true
            ;;
        "--books-summary"|"-bs")
            BOOKS_SUM=true
            ;;
        "--force"|"-f")
            FORCE=true
            ;;
        *)
            echo "SYNTAX ERROR: $1"
            exit 1
            ;;
    esac
    shift
done

#
# Get latest JSON
#
if [ ! -f $JD_STAT_JSON ] || [ "$FORCE" = "true" ]
then
    rm -f $JD_STAT_JSON
    wget $JD_STAT_URL/$JD_STAT_JSON
fi

title()
{
    echo "--------------------------"
    echo "   $1"
    echo "--------------------------"
}

TODAY_JSON=jd-$DATE.json
cat jd-complete.json | jq ".\"juneday-stats\"[] | select(.date==\"$DATE\").\"daily-stats\"" > $TODAY_JSON

if [ "$BOOKS" = "true" ]
then
    title "Books"
    cat $TODAY_JSON  | jq '.books[]|.title,.pages'
fi

if [ "$BOOKS_SUM" = "true" ]
then
    title "Books summary"
    cat $TODAY_JSON  | jq '."book-summary"'
fi
