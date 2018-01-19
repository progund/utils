#!/bin/bash

TEMP_DIR=/tmp/junedaywiki
DEST_DIR_BASE=/var/www/html/junedaywiki-stats
PDF_DIR_BASE=/var/www/html/juneday-pdf
PATH=${PATH}:.
CURR_DIR=$(pwd)
DOWNLOAD=true
DATE=$(date '+%Y%m%d')
DEST_DIR=${DEST_DIR_BASE}/${DATE}/

if [ "$1" = "--test-conf" ]
then
    if [ ! -f $2 ]
    then
        echo "Missing test conf file: $2"
        exit 2
    fi
    . $2
    shift
    shift
fi

mkdir -p "$DEST_DIR"
export LOG_FILE=$DEST_DIR/juneday-stats.log

export HTML_STATS=${DEST_DIR_BASE}/jd-stat.html

STAT_FILE=$DEST_DIR/stat.json
JD_STAT_FILE=$DEST_DIR/jd-stats.json

mkdir -p "$DEST_DIR"
rm -f $STAT_FILE

mkdir -p "$TEMP_DIR"


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
    
    if [ "$1" = "--graph" ]
    then
        GRAPH=true
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

print_first_entry()
{
    REGEXP="$1"
    JSON_FILE="$2"
    printf "%6s " $(grep "$REGEXP" "$JSON_FILE" | head -1 | sed 's/[",]*//g' | awk ' { printf "%s", $2}')" "
}

print_last_entry()
{
    REGEXP="$1"
    JSON_FILE="$2"
    printf "%6s " $(grep "$REGEXP" "$JSON_FILE" | tail -1 | sed 's/[",]*//g' | awk ' { printf "%s", $2}')" "
}


init_html()
{
    cat <<EOF
<html>
<body>
<style type="text/css">

.rTable {
  	display: table;
  	width: 100%;
}
.rTableRow {
  	display: table-row;
}
.rTableHeading {
  	display: table-header-group;
  	background-color: #ddd;
}
.rTableCell, .rTableHead {
  	display: table-cell;
  	padding: 3px 10px;
  	border: 1px solid #999999;
}
.rTableHeading {
  	display: table-header-group;
  	background-color: #ddd;
  	font-weight: bold;
}
.rTableFoot {
  	display: table-footer-group;
  	font-weight: bold;
  	background-color: #ddd;
}
.rTableBody {
  	display: table-row-group;
}
</style>
EOF
}

html_stat()
{
    echo "$*" >> $HTML_STATS
}

day_one_html()
{
cat <<EOF
<div class="rTableRow">
<div class="rTableCell">20160616</div>
<div class="rTableCell"> 0 </div>
<div class="rTableCell"> 0 </div>
<div class="rTableCell"> 0 </div>
<div class="rTableCell"> 0 </div>
<div class="rTableCell"> 0 </div>
<div class="rTableCell"> 0 </div>
<div class="rTableCell"> 0 </div>
<div class="rTableCell"> 0 </div>
<div class="rTableCell">0 </div>
<div class="rTableCell">0 </div>
<div class="rTableCell">0 </div>
<div class="rTableCell">0 </div>
</div>
EOF
}

day_sep_html()
{
cat <<EOF
<div class="rTableRow">
<div class="rTableCell">-</div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
<div class="rTableCell"> - </div>
</div>
EOF
}



gen_graph()
{
#    REGEXPS_HEAD="books pages uniq-presentations uniq-presentations-pages uniq-channels  uniq-videos podcasts"
    REGEXPS_HEAD="books pages uniq-presentations uniq-presentations-pages "
    REGEXPS_TAIL="videos podcasts   "
    SOURCE_SUFF="Java C Bash Build"
    pushd ${DEST_DIR_BASE} 2>/dev/null >/dev/null 

    init_html > $HTML_STATS

    log_to_file "---> gen_graph()"

    html_stat '<h2>Stats for Juneday</h2>'
    html_stat '<div><div class="rTable">'
    html_stat '<div class="rTableRow">'

    echo -n "# date "
    html_stat '<div class="rTableHead"><strong>Date</strong></div>'
    html_stat '<div class="rTableHead"><strong>Books</strong></div>'
    html_stat '<div class="rTableHead"><strong>Pages</strong></div>'
    html_stat '<div class="rTableHead"><strong>Presentations</strong></div>'
    html_stat '<div class="rTableHead"><strong>Presentation pages</strong></div>'
#    html_stat '<div class="rTableHead"><strong>Vimeo channels</strong></div>'
#    html_stat '<div class="rTableHead"><strong>Vimeo videos</strong></div>'
    html_stat '<div class="rTableHead"><strong>Videos</strong></div>'
    html_stat '<div class="rTableHead"><strong>Podcasts</strong></div>'
#    html_stat '<div class="rTableHead"><strong>Content pages</strong></div>'
 #   html_stat '<div class="rTableHead"><strong>Actual pages</strong></div>'

    for i in $SOURCE_SUFF
    do
        html_stat '<div class="rTableHead"><strong>LOC ('$i')</strong></div>'
    done
    html_stat '<div class="rTableHead"><strong>LOC (Source Code Total)</strong></div>'
    html_stat '<div class="rTableHead"><strong>LOC (Doc)</strong></div>'
    for re in $REGEXPS_HEAD  $REGEXPS_TAIL
    do
    #    html_stat '<div class="rTableHead"><strong>'$re'</strong></div>'
	printf "%s " ${re} 
    done
    for i in $SOURCE_SUFF
    do
     #   html_stat '<div class="rTableHead"><strong>'$i'</strong></div>'
	printf "%s " "$i" 
    done
    printf "Total" 
    html_stat '</div>'
    echo

    day_one_html  >> $HTML_STATS
    day_sep_html  >> $HTML_STATS
    
    for dir in $(ls -1d 20* | sort -n -r)
    do
        html_stat '<div class="rTableRow">'
	log_to_file "---  gen_graph() -- dir: $dir"
	echo -n "$dir "
        html_stat '<div class="rTableCell">'$dir'</div>'
	for re in $REGEXPS_HEAD
	do
            ENTRY=$(print_first_entry "$re" "$dir/jd-stats.json")
            html_stat '<div class="rTableCell">'$ENTRY'</div>'
            print_first_entry "$re" "$dir/jd-stats.json"
	done
	for re in $REGEXPS_TAIL
	do
            ENTRY=$(print_last_entry "$re" "$dir/jd-stats.json")
            html_stat '<div class="rTableCell">'$ENTRY'</div>'
	    print_last_entry "$re" "$dir/jd-stats.json"
	done
	#
	# src code
	#
        SOURCE_TOT=0
	for i in $SOURCE_SUFF
	do
	    SOURCE_STUFF=`echo -n $(grep -B 2 "\"type\": \"$i" "$dir/jd-stats.json" | head -1 | awk ' {  print $2 } ' | sed -e 's/"//g' -e 's/,//g' -e 's,[ ]*,,g')""`
	    
            if [ "$SOURCE_STUFF" = "" ]  ; then SOURCE_STUFF=0; fi
            html_stat '<div class="rTableCell">'$SOURCE_STUFF'</div>'
	    echo -n $(grep -B 2 "\"type\": \"$i" "$dir/jd-stats.json" | head -1 | awk ' {  print $2 } ' | sed -e 's/"//g' -e 's/,//g')" "
            SOURCE_TOT=$(( $SOURCE_TOT + $SOURCE_STUFF ))
	done
        html_stat '<div class="rTableCell">'$SOURCE_TOT'</div>'
	DOC_LOC=`echo -n $(grep -B 2 "\"type\": \"Doc" "$dir/jd-stats.json" | head -1 | awk ' {  print $2 } ' | sed -e 's/"//g' -e 's/,//g'  -e 's,[ ]*,,g')" "`
        if [ "$DOC_LOC" = "" ]  || [ "$DOC_LOC" = " " ]  ; then DOC_LOC=0; fi
        html_stat '<div class="rTableCell">'$DOC_LOC'</div>'
	echo
        html_stat '</div>'
    done
    html_stat '</div>'
    html_stat '</body>'
    html_stat '</html>'

    popd  2>/dev/null >/dev/null 
    log_to_file "<--- gen_graph()"
}

big_json()
{
    log_to_file "---> big_json()"
    cd ${DEST_DIR_BASE}
    echo "{" 
    echo "  \"juneday-stats\": [" 

    DIR_CNT=0
    for dir in $(ls -1d 20* | sort -n)
    do
	log_to_file "---  big_json()  dir: $dir"

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
    log_to_file "<--- big_json()"

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


    if [ "$GRAPH" = "true" ]
    then
	gen_graph > ${DEST_DIR_BASE}/jd-stat.data
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
        log_to_file "    -- handle book: $book ($?)"
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

    ls -al ${STAT_FILE}
    ls -al ${JD_STAT_FILE}
    cat ${STAT_FILE} | python -mjson.tool > ${JD_STAT_FILE}
    echo "    conv ${STAT_FILE} to  ${JD_STAT_FILE} returned $?"
#    jsonlint  ${JD_STAT_FILE}
    ls -al ${STAT_FILE}
    cp ${STAT_FILE} /tmp/stat-keep.json
    ls -al ${JD_STAT_FILE}

    #
    # Copy all pdfs
    #
    mkdir -p ${PDF_DIR_BASE}/${DATE}
    cp -r ${TEMP_DIR} ${PDF_DIR_BASE}/${DATE}


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



