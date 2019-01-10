#!/bin/bash


TMP_DIR=${HOME}/.jd-tmp
LOG_URL=http://rameau.sandklef.com/junedaywiki-stats/
MAX_AGE_MINS=30

date_to_file(){
    echo $TMP_DIR/jd-stats-${1}.json
}

makedir()
{
    if [ ! -d $1 ]
    then
        mkdir $1
    fi
}

download()
{
    DATE=$1
    FILE=jd-stats-${DATE}.json
    URL=${LOG_URL}/${DATE}/jd-stats.json
    
    OLD=$(find ${TMP_DIR} -name $FILE -type f -mmin +${MAX_AGE_MINS} 2>/dev/null| wc -l)
    if [ ! -f $TMP_DIR/$FILE ] || [ $OLD -ne 0 ]
    then
        echo "Download $URL to $TMP_DIR/$FILE"
        curl $URL -o $TMP_DIR/$FILE
    fi

    jsonlint-php $TMP_DIR/$FILE 2>/dev/null >/dev/null
    RET=$?

    if [ $RET -ne 0 ]
    then
        echo "Bad JSON file, removing: $TMP_DIR/$FILE"
        echo ""
        echo "Try again"
        rm $TMP_DIR/$FILE
        exit 1
    fi
    
}

arg_to_date() {
    DATE_ARG=$1
    SIZE=$(echo ${#DATE_ARG})

    RET_DATE=""

    if [ "$DATE_ARG" = "" ]
    then
    # missing arg
        :
    elif [ $SIZE -lt 5 ]
    then
        # less than 5 digits -> "days old"
        RET_DATE=$(date --date="$DATE_ARG day ago" +%Y%m%d)
    elif [ $SIZE -eq 8 ]
    then
        # 8 digits -> date
        RET_DATE=$DATE_ARG
    else
        :
    fi
        
    echo $RET_DATE 
}

parse()
{
    if [ $# -eq 2 ]
    then
        START_DATE=$(arg_to_date $1)
        STOP_DATE=$(arg_to_date $2)
    elif [ $# -eq 1 ]
    then
        START_DATE=$(arg_to_date $1)
        STOP_DATE=$(arg_to_date 0)
    else
        START_DATE=$(arg_to_date 7)
        STOP_DATE=$(arg_to_date 0)
    fi

    if [ "$START_DATE" = "" ]
    then
        START_DATE=$(date --date="7 day ago" +%Y%m%d)
    fi
    if [ "$STOP_DATE" = "" ]
    then
        STOP_DATE=$(date +%Y%m%d)
    fi

    DAYS=$(( ($(date --date="$STOP_DATE" +%s) - $(date --date="$START_DATE" +%s) )/(60*60*24) ))

    if [ $DAYS -le 0 ]
    then
        echo "Invalid dates:"
        echo " * start: $START_DATE"
        echo " * stop: $STOP_DATE"
        echo " * gives diff: $DAYS"
        exit 1
    fi
}


#
# main
#
parse $*
makedir $TMP_DIR

download $START_DATE
download $STOP_DATE


    HEADER="===================================================================="
SUB_HEADER="--------------------------------------------------------------------"

FMT="%-35s %6s %6s\t%-6s\t%-6s\n"
print_diff_header() {
    printf "$FMT" $1 $2 $3 $4 $5
    #$6
}

print_diff() {
    HEADER=$1
    START_VAL=$2
    STOP_VAL=$3

    if [ "$START_VAL" = "null" ] || [ "$START_VAL" = "" ]
    then
        START_VAL=0
    fi

    DIFF=$(( $STOP_VAL - $START_VAL ))
    DAILY_DIFF=$(echo "scale=2;$DIFF / $DAYS" | bc -l)
    printf "$FMT" "$HEADER:" $DIFF $DAILY_DIFF $START_VAL $STOP_VAL #$DAYS
}


books_helper(){
    cat $1  | jq '."book-summary"|.books,.pages' | sed 's,",,g' | while (true) ; do
        read BOOKS
        read PAGES
        if [ "$BOOKS" = "" ] ; then break ; fi
        echo "$BOOKS $PAGES"
    done
}

books(){
    START=$(books_helper $(date_to_file ${START_DATE}))
    START_BOOKS=${START% *}
    START_PAGES=${START#* }

    STOP=$(books_helper $(date_to_file ${STOP_DATE}))
    STOP_BOOKS=${STOP% *}
    STOP_PAGES=${STOP#* }

    print_diff "Books summary" "$START_BOOKS" "$STOP_BOOKS"
}

code_helper()
{

    REPOS=$(cat $1 | jq '."git-repos".total' | sed -e 's,",,g')
    COMMITS=$(cat $1  | jq  ".\"git-repos\".\"git-repo-stat\"[].\"repo-commits\"" | sed -e 's,",,g' | tr '\n' '+' | sed 's,+$,\n,g' | bc)
    TOT_LOC=$(cat $1 | jq '."source-code"[]."lines-of-code"' | sed 's,",,g' | tr '\n' '+' | sed 's,+$,\n,g' | bc -l)
    echo "$REPOS|$COMMITS|$TOT_LOC::"
    cat $1 | jq '."source-code"[]|.type,."lines-of-code"'| sed 's,",,g' | while (true) ; do
        read TYPE
        read LOC
        if [ "$TYPE" = "" ] ; then break ; fi
        echo "$TYPE|$LOC"
    done
}

code() {
    START=$(code_helper $(date_to_file ${START_DATE}))
    SUM=$(echo $START | sed 's,::,\n,g' | head -1)
 #   echo $START
    CODES=$(echo $START | sed 's,::,::\n,g' | grep -v "::")
    START_REPOS=$(echo $SUM | cut -d'|' -f 1)
    START_COMMITS=$(echo $SUM | cut -d'|' -f 2)
    START_TOT_LOC=$(echo $SUM | cut -d'|' -f 3)
    declare -A START_CODE
    for code in $CODES
    do
        TYPE=$(echo $code | cut -d'|' -f 1)
        LOC=$(echo $code | cut -d'|' -f 2)
        START_CODE[$TYPE]=$LOC
    done
    
    STOP=$(code_helper $(date_to_file ${STOP_DATE}))
    SUM=$(echo $STOP | sed 's,::,\n,g' | head -1)
#    echo $STOP
    CODES=$(echo $STOP | sed 's,::,::\n,g' | grep -v "::")
    STOP_REPOS=$(echo $SUM | cut -d'|' -f 1)
    STOP_COMMITS=$(echo $SUM | cut -d'|' -f 2)
    STOP_TOT_LOC=$(echo $SUM | cut -d'|' -f 3)
    declare -A STOP_CODE
    for code in $CODES
    do
        TYPE=$(echo $code | cut -d'|' -f 1)
        LOC=$(echo $code | cut -d'|' -f 2)
        STOP_CODE[$TYPE]=$LOC
    done
    

    print_diff "Repositories" "$START_REPOS" "$STOP_REPOS"
    print_diff "Commits" "$START_COMMITS" "$STOP_COMMITS"

    TOT_CODE=0
    echo "Language loc:"
    for i in "${!STOP_CODE[@]}"
    do
        print_diff " * $i" "${START_CODE[$i]}" "${STOP_CODE[$i]}"
        if [ "${START_CODE[$i]}" = "" ]
        then
            START_CODE[$i]=0
        fi
        TOT_CODE=$(( $TOT_CODE -  ${START_CODE[$i]} + ${STOP_CODE[$i]} ))
    done
    print_diff "Total loc" "$START_TOT_LOC" "$STOP_TOT_LOC"
#    print_diff "LOCS in total" 0 $TOT_CODE

}



books_individuals_helper() {
    BOOKS=$(cat $1  | jq '.books[]|.title,.pages' | sed 's,",,g' | while (true) ; do
                read NAME
                read PAGES
                if [ "$PAGES" = "" ] ; then break ; fi
                echo -n "$NAME:$PAGES###"
            done | grep -v "^[ ]*$")
    echo $BOOKS
}

books_individuals() {
    SAVED_IFS=$IFS
    BOOKS=$(books_individuals_helper $(date_to_file $START_DATE))
    declare -A START_BOOKS
    export IFS="###"
    for book in $BOOKS
    do
#        echo "book: $book"
        if [ "$book" = "" ] ; then continue; fi
        BOOK_TITLE=$(echo $book | cut -d':' -f 1)
        BOOK_PAGES=$(echo $book | cut -d':' -f 2)
        if [ "$BOOK_TITLE" = "" ] ; then continue; fi
#        echo "START_BOOKS[$BOOK_TITLE]=$BOOK_PAGES"
        START_BOOKS[$BOOK_TITLE]=$BOOK_PAGES
    done
    IFS=$SAVED_IFS

    SAVED_IFS=$IFS
    BOOKS=$(books_individuals_helper $(date_to_file $STOP_DATE))
    declare -A STOP_BOOKS
    export IFS="###"
    for book in $BOOKS
    do
 #       echo "book: $book"
        if [ "$book" = "" ] ; then continue; fi
        BOOK_TITLE=$(echo $book | cut -d':' -f 1)
        BOOK_PAGES=$(echo $book | cut -d':' -f 2)
        if [ "$BOOK_TITLE" = "" ] ; then continue; fi
        STOP_BOOKS[$BOOK_TITLE]=$BOOK_PAGES
    done
    IFS=$SAVED_IFS

    TOT_PAGES=0
    echo "Book stats:"
    for i in "${!STOP_BOOKS[@]}"
    do
        print_diff " * $i" "${START_BOOKS[$i]}" "${STOP_BOOKS[$i]}"
        TOT_PAGES=$(( $TOT_PAGES - ${START_BOOKS[$i]} + ${STOP_BOOKS[$i]} ))
    done
    print_diff "Pages in total" 0 $TOT_PAGES
}


echo
echo "Worklog statistics between $START_DATE and $STOP_DATE ($DAYS days)"
echo $HEADER
echo 
echo $SUB_HEADER
print_diff_header "type" "diff" "daily" "start" "stop" "days"
echo $SUB_HEADER
echo
books
books_individuals
echo 
echo "Source code"
echo $SUB_HEADER
code



