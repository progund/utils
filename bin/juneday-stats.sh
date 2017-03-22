#!/bin/bash

TEMP_DIR=/tmp/junedaywiki
DEST_DIR_BASE=/tmp/var/www/html/junedaywiki-stats
PATH=${PATH}:.
CURR_DIR=$(pwd)
DOWNLOAD=true
DEST_DIR=${DEST_DIR_BASE}/$(date '+%Y%m%d')/
mkdir -p $DEST_DIR
export LOG_FILE=$DEST_DIR/juneday-stats.log


STAT_FILE=$DEST_DIR/stat.json
JD_STAT_FILE=$DEST_DIR/jd-stats.json

mkdir -p $DEST_DIR
rm -f $STAT_FILE


mkdir -p $TEMP_DIR
declare -A PAGE_COUNTS

#
# Source bash-functions
#
#
THIS_SCRIPT_DIR=$(dirname $0)
BASH_FUNCTIONS=${THIS_SCRIPT_DIR}/bash-functions
if [ -f ${BASH_FUNCTIONS} ]
then
    echo "Sourcing file:  ${BASH_FUNCTIONS}"
    . ${BASH_FUNCTIONS}
    determine_os
else
    echo -n "Failed finding file: ${BASH_FUNCTIONS}. "
    echo "Bailing out..."
    exit 1
fi

#
# Source in functions
#
#
HELPER_FILES="git-functions src-functions wiki-functions video-functions pod-functions"
if [ -d ${THIS_SCRIPT_DIR} ]
then
    echo "Sourcing helper files"
    for f in $HELPER_FILES
    do
        SH_FILE=$THIS_SCRIPT_DIR/../lib/stats/$f
        if [ -f $SH_FILE ]
        then
            echo "source $SH_FILE"
            . ${SH_FILE}
        else
            echo "Missing file: $SH_FILE"
            echo "Current directory: $(pwd)"
            exit 2
        fi
    done
else
    echo "Bailing out..."
    exit 1
fi

parse()
{
    log_to_file "parsing user arguments"
    if [ "$1" = "-nd" ]
    then
        DOWNLOAD=false
        shift
    fi
    
    if [ "$1" = "--big-json" ]
    then
        BIG_JSON=true
	shift
    fi
    
    BOOK_CONF=$1
    if [ ! -f $BOOK_CONF ] || [ "$BOOK_CONF" = "" ]
    then
        if [ ! -f $BOOK_CONF ]
        then
            echo "missing: $BOOK_CONF"
            ls -al
            exit 1
        fi
        echo "Missing or faulty book configuration file ($BOOK_CONF)"
        exit 1
    fi
    . $BOOK_CONF
}

big_json()
{
    cd ${DEST_DIR_BASE}
    echo "{" 
    echo "  \"juneday-stats\": [" 

    DIR_CNT=0
    for dir in $(ls -1d 20* | sort -n)
    do
	if [ $DIR_CNT -ne 0 ]
	then
	    echo ","
	fi
	DIR_CNT=$(( DIR_CNT + 1 ))
	echo "  {"
	echo "\"date\":\"$dir\"",
	echo "\"daily-stats\":"
	cat $dir/jd-stats.json
	echo "  }"
    done
    
    echo "  ]"
    echo "}"

}

main()
{
    
    log_to_file "--> main"

    if [ "$BIG_JSON" = "true" ]
    then
	big_json >  ${DEST_DIR_BASE}/jd-tmp.json
	cat ${DEST_DIR_BASE}/jd-tmp.json | python -mjson.tool > ${DEST_DIR_BASE}/jd-complete.json
	exit 0
    fi

    debug "BOOKS: $BOOKS"
    PRES_PDFS=""
    TOTAL_PAGE_COUNT=0
    log_to_file "  --> looping through books"

    echo "{" >> $STAT_FILE
    echo " \"books\": [" >> $STAT_FILE

    BOOK_COUNT=0
    for book in $BOOKS
    do
        if [ $BOOK_COUNT -ne 0 ]
        then
            echo "," >> $STAT_FILE
        fi
        BOOK_COUNT=$(( BOOK_COUNT + 1 ))
        log_to_file "    --> handle book: $book"
        check_book $book >> $STAT_FILE
        log_to_file "    -- handle book: $book"
    done
    log_to_file "  <-- looping through books"
    echo "  ],"  >> $STAT_FILE
    
    log_to_file "  --> Check presentation pdfs"
    check_pres_pdfs_vids >> $STAT_FILE
    log_to_file "  <-- Check presentation pdfs"

    log_to_file "  --> Getting wiki stats"
    get_wiki_stats >> $STAT_FILE
    echo "," >> $STAT_FILE
    log_to_file "  <-- Getting wiki stats"

    log_to_file "  --> downloading source code"
    dload_source_code
    log_to_file "  <-- downloading source code"
    
    log_to_file "  --> Creating stats for source code"
    source_code_stat >> $STAT_FILE
    echo "    , " >> $STAT_FILE
    log_to_file "  <-- Creating stats for source code"

    log_to_file "  --> Creating stats for git"
    git_stats >> $STAT_FILE
    echo "    , " >> $STAT_FILE
    log_to_file "  <-- Creating stats for git"
#    echo "]">> $STAT_FILE

    log_to_file "  --> Creating stats from vimeo"
    get_vimeo_stat >> $STAT_FILE
    echo "    , " >> $STAT_FILE
    log_to_file "  <-- Creating stats from vimeo"

    log_to_file "  --> Creating stats from vimeo"
    get_pod_stat >> $STAT_FILE
    log_to_file "  <-- Creating stats from vimeo"

    
    echo "}" >> $STAT_FILE

    echo "    conv ${STAT_FILE} to  ${JD_STAT_FILE}"

    cat ${STAT_FILE} | python -mjson.tool > ${JD_STAT_FILE}
#    jsonlint  ${JD_STAT_FILE}
    return
    
    #
    # Summary
    #
    printf "\n --== %s ==-- \n" "Books"
    log_to_file "  --> looping through books (again)"
    for book in $BOOKS
    do
        log_to_file "    --> handle book: $book"
        TITLE_VAR=${book}_TITLE
        TITLE=${!TITLE_VAR}
        echo -n "${TITLE}: "
        echo ${PAGE_COUNTS[$book]}
        log_to_file "    -- handle book: $book"
    done
    log_to_file "  <-- looping through books (again)"

    echo "Total: $TOTAL_PAGE_COUNT"
    printf "\n --== %s ==-- \n" "Presentation pdfs"
    echo "$TOTAL_PRES_PAGE_COUNT"

}


parse $*
cd  $TEMP_DIR
main



