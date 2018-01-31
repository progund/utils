#!/bin/bash

DATE=$(date '+%Y%m%d')

JD_STAT_URL=http://rameau.sandklef.com/junedaywiki-stats
JD_STAT_JSON=jd-complete.json


usage()
{
    echo "NAME"
    echo "       get-stats.sh - get statistics from Juneday's JSON file"
    echo ""
    echo "SYNOPSIS"
    echo "       get-stats.sh"
    echo ""
    echo "DESCRIPTION"
    echo "       "
    echo "OPTIONS"
    echo "       -f, --force"
    echo "           force download of JSON file"
    echo ""
    echo "       -bs, --books-summary"
    echo "           print summary of books"
    echo ""
    echo "       -b, --books"
    echo "           print pages for each books"
    echo ""
    echo "       -h, --help"
    echo "           print this help message"
    echo ""
    echo "RESTURN VALUES"
    echo "        0 - success"
    echo "        2 - wrong paramaters"
}

while [ "$1" != "" ]
do
    case "$1" in
        "--date")
            DATE=$2
            shift
            ;;
        "--help")
            usage
            exit 0
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
            echo
            usage
            exit 2
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
