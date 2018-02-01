#!/bin/bash

DATE=$(date '+%Y%m%d')

JD_STAT_URL=http://rameau.sandklef.com/junedaywiki-stats
JD_STAT_JSON=jd-complete.json


#
FORCE=false

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
    echo "       -ws, --wiki-summary"
    echo "           print wiki summary"
    echo ""
    echo "       -ps, --podcast-summary"
    echo "           print podcast summary"
    echo ""
    echo "       -a, --all-summaries"
    echo "           print all summaries"
    echo ""
    echo "       -h, --help"
    echo "           print this help message"
    echo ""
    echo "       -v, --verbose"
    echo "           print verbose messages (to stderr)"
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
        "--videos-summary"|"-vs")
            VIDEOS_SUM=true
            ;;
        "--wiki-summary"|"-ws")
            WIKI_SUM=true
            ;;
        "--code-summary"|"-cs")
            CODE_SUM=true
            ;;
        "--podcast-summary"|"-ps")
            POD_SUM=true
            ;;
        "--verbose"|"-v")
            VERBOSE=true
            ;;
        "--force"|"-f")
            FORCE=true
            ;;
        "--all-summaries"|"-a")
            BOOKS=true
            BOOKS_SUM=true
            VIDEOS_SUM=true
            WIKI_SUM=true
            CODE_SUM=true
            POD_SUM=true
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


verbose()
{
    if [ "$VERBOSE" = "true" ]
    then
        echo "$*" 1>&2
    fi
}

DAILY_JSON=jd-$DATE.json
#
# Get latest JSON
#
FRESH_FILE=$(find $JD_STAT_JSON -cmin +10 | wc -l)
verbose "Settings"
verbose " * date:       $DATE"
verbose " * force:      $FORCE"
verbose " * big json:   $JD_STAT_JSON | $(ls -al $JD_STAT_JSON 2>/dev/null | wc -l)"
verbose " * daily json: $DAILY_JSON  | $(ls -al $DAILY_JSON 2>/dev/null | wc -l)"
verbose " * fresh file: $FRESH_FILE"
if [ ! -f $JD_STAT_JSON ] || [ "$FORCE" = "true" ] || [ $FRESH_FILE -ne 0 ]
then
    verbose "Removing \"$JD_STAT_JSON\""
    rm -f $JD_STAT_JSON
    verbose "Downloading \"$JD_STAT_JSON\""
    verbose " * url: $JD_STAT_URL/$JD_STAT_JSON"
    wget $JD_STAT_URL/$JD_STAT_JSON
else
    verbose "Reusing big JSON \"$JD_STAT_JSON\""
fi

if [ ! -f $DAILY_JSON ]
then
    verbose "Creating daily JSON file \"$DAILY_JSON\" from \"$JD_STAT_JSON\""
    echo 'cat $JD_STAT_JSON | jq ".\"juneday-stats\"[] | select(.date==\"$DATE\").\"daily-stats\"" > $DAILY_JSON'
    cat $JD_STAT_JSON | jq ".\"juneday-stats\"[] | select(.date==\"$DATE\").\"daily-stats\"" > $DAILY_JSON
else
    verbose "Reusing daily JSON \"$DAILY_JSON\""
fi

title()
{
    echo
    echo "--------------------------"
    echo "   $1"
    echo "--------------------------"
}


books()
{
    cat $DAILY_JSON  | jq '.books[]|.title,.pages' | sed 's,",,g' | while (true) ; do
        read NAME
        read PAGES
        if [ "$NAME" = "" ] ; then break ; fi
        printf " %-40s %.d\n" "$NAME:" $PAGES
    done
}

books_sum()
{
    cat $DAILY_JSON  | jq '."book-summary"|.books,.pages' | sed 's,",,g' | while (true) ; do
        read BOOKS
        read PAGES
        if [ "$BOOKS" = "" ] ; then break ; fi
        printf " Number of books: %d\n" $BOOKS 
        printf " Number of pages in books: %d\n" $PAGES
    done
}

videos_sum()
{
    echo -n " Videos at Vimeo: "
    cat $DAILY_JSON  | jq '."vimeo-stats".videos' | sed 's,",,g'
}

wiki_sum()
{
    cat $DAILY_JSON | jq '."wiki-stats"|."content-pages",."uploaded-files"'| sed 's,",,g' | while (true) ; do
        read CPAGES
        read UFILES
        if [ "$CPAGES" = "" ] ; then break ; fi
        printf " Number of pages: %d\n" $CPAGES
        printf " Number of uploaded files: %d\n" $UFILES
    done
}

code_sum()
{
    echo " Number of repositories: $(cat $DAILY_JSON | jq '."git-repos".total')" | sed 's,",,g'

    TOT_LOC=$(cat $DAILY_JSON | jq '."source-code"[]."lines-of-code"' | sed 's,",,g' | tr '\n' '+' | sed 's,+$,\n,g' | bc -l)
    echo " Programming languages: $TOT_LOC"
    cat $DAILY_JSON | jq '."source-code"[]|.type,."lines-of-code"'| sed 's,",,g' | while (true) ; do
        read TYPE
        read LOC
        if [ "$TYPE" = "" ] ; then break ; fi
        printf "   %-10s %d\n" "$TYPE:" $LOC
    done
}

pod_sum()
{
    echo -n " Podcasts: "
    cat $DAILY_JSON | jq '.pod.podcasts' | sed 's,",,g'
}


title "Date: $DATE"

if [ "$BOOKS" = "true" ]
then
    title "Books"
    books
fi

if [ "$BOOKS_SUM" = "true" ]
then
    title "Books summary"
    books_sum
fi

if [ "$VIDEOS_SUM" = "true" ]
then
    title "Videos summary"
    videos_sum
fi

if [ "$WIKI_SUM" = "true" ]
then
    title "Wiki summary"
    wiki_sum
fi

if [ "$CODE_SUM" = "true" ]
then
    title "Source code summary"
    code_sum
fi

if [ "$POD_SUM" = "true" ]
then
    title "Podcast summary"
    pod_sum
fi


echo
