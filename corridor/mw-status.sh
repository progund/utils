#!/bin/bash

##############################################
#
# Script to generate status page, typically for use in a KIOSK
# computer
#
##############################################


#
#
#
THIS_SCRIPT_DIR=$(dirname $0)


#
# Directory with JSON logs
#
export JD_STAT_DIR=/var/www/html/junedaywiki-stats

#
# Directory to put resulting crap in
#
export WWW_DIR=/var/www/html/status/


########## FUNCTIONS ETC ##############

usage()
{
    echo "mw-status.sh"
    echo ""
    echo "Simple script to generate html pages (actually one)"
    echo "for display in a kiosk mode computer"
    echo ""
    echo ""
    echo ""
    echo "If the environment variable LOCAL_ETC is set"
    echo "and points to a valid file (hrmm... you get it!)"
    echo ".. then that file is sourced"
    echo "To debug locally:"
    echo "    LOCAL_ETC=local-mw-etc.conf ./mw-status.sh"
    echo ""
    echo ""
}


if [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
    usage
    exit 0
fi

TODAY=$(date '+%Y%m%d')
WEEK_AGO=$(date --date "-7 days" '+%Y%m%d')

#JD_DIR=$(find ${JD_STAT_DIR}/ -type d -name "20*" 2>/dev/null | sort | tail -1)
JD_DIR=${JD_STAT_DIR}/$TODAY
JD_FILE=${JD_DIR}/jd-stats.json
JD_WEEK_AGO_FILE=${JD_STAT_DIR}/$WEEK_AGO/jd-stats.json

#
# Local etc file, used if present
#
if [ "${LOCAL_ETC}" != "" ]
then
    echo "Using local etc file: '${LOCAL_ETC}'"
    if [ -f ${LOCAL_ETC} ]
    then
        . ${LOCAL_ETC}
    else
        echo "Local etc file '${LOCAL_ETC}' missing"
        usage
        exit 1
    fi
fi


if [ ! -f ${JD_FILE} ] ||  [ ! -f ${JD_WEEK_AGO_FILE} ] 
then
    echo "Missing JSON file(s)"
    echo " * ${JD_FILE}"
    echo " * ${JD_WEEK_AGO_FILE}"
    exit 1
fi

tofile()
{
    echo "$*" >> $TOFILE
}

print_tag()
{
    tofile "$1: " $(cat $JD_FILE | jq -r ".$2")
}

print_week_tag()
{
    NOW=$(cat $JD_FILE | jq -r ".$2")
    THEN=$(cat $JD_WEEK_AGO_FILE | jq -r ".$2")
    tofile "$1: $(( $NOW - $THEN ))       $NOW | $THEN"  
}


gen_page_2()
{
    TOFILE=$1
    tofile "<html>"
    tofile "<head>"
    #tofile "<meta http-equiv=\"refresh\" content=\"10;index.html\"   >"
    tofile "</head>"
    tofile "<title>"
    tofile "Worklog for Rikard and Henrik"
    tofile "</title>"
    tofile "<body>"
    tofile "<center>"
    tofile "<h1>Stats from our wiki</h1>"
    tofile "<h2>"
    print_tag "Number of Wiki books" "[\"book-summary\"].books"
    print_tag "Number of pages in our Wiki books" "[\"book-summary\"].pages"
    print_tag "Number of presentations" "[\"book-summary\"].\"uniq-presentations\""
    print_tag "Number of presentation pages" "[\"book-summary\"].\"uniq-presentations-pages\""
    print_tag "Number of linked videos" "[\"book-summary\"].\"uniq-videos\""

    tofile "</h2>"
    tofile "<h1>Stats from the source code use in our courses </h1>"
    tofile "<h2>"
    print_tag "Number of public repos" "[\"git-repos\"].total"
    NR_OF_LANG=$(cat $JD_FILE |  jq -r '.["source-code"]|length')
    #tofile "LANGS: $NR_OF_LANG"
    export CNT=0
    while [ $CNT -lt $NR_OF_LANG ]
    do
        #    tofile "CNT: $CNT"
        JD_LOC=$(cat $JD_FILE | jq -r  ".[\"source-code\"][$CNT].\"lines-of-code\"")
        JD_LANG=$(cat $JD_FILE | jq -r  ".[\"source-code\"][$CNT].\"type\"")
        tofile "Lines of $JD_LANG code: $JD_LOC"
        tofile "<br>"
        CNT=$(( $CNT + 1 ))
    done
    tofile "</h2>"
    tofile "<h1>Stats from Vimeo</h1>"
    tofile "<h2>"
    print_tag "Number of Vimeo videos" "[\"vimeo-stats\"].\"videos\""
    tofile "</h2>"
    tofile "<h1>Weekly stats</h1>"
    tofile "<h2>"
    print_week_tag "Last weeks new pages:" "[\"book-summary\"].pages"
    print_week_tag "Last weeks new presentations" "[\"book-summary\"].\"uniq-presentations\""
    print_week_tag "Last weeks new videos" "[\"vimeo-stats\"].\"videos\""
    tofile "</h2>"
    tofile "</center>"
    tofile "</body>"
    tofile "</html>"
}

copy_if_not_here()
{
    #    echo "copy $1 ${WWW_DIR} ????"
    if [ ! -f ${WWW_DIR}/$1 ]
    then
        #       echo "cp $1 ${WWW_DIR}/"
        cp $1 ${WWW_DIR}/
    fi
}


#
# Copy/generate HTML files
#
copy_if_not_here ${THIS_SCRIPT_DIR}/../../utils-blobs/images/cropped-jd.jpg 
copy_if_not_here ${THIS_SCRIPT_DIR}/../../utils-blobs/images/loonies.jpg
copy_if_not_here ${THIS_SCRIPT_DIR}/../../utils-blobs/images/math.jpg
copy_if_not_here ${THIS_SCRIPT_DIR}/../../utils-blobs/images/h-and-r-1.jpg
copy_if_not_here ${THIS_SCRIPT_DIR}/../../utils-blobs/images/spying.jpg
copy_if_not_here ${THIS_SCRIPT_DIR}/../../utils-blobs/images/stupid.jpg
copy_if_not_here ${THIS_SCRIPT_DIR}/../../utils-blobs/images/Felix.jpg


cp ${THIS_SCRIPT_DIR}/index.html  ${WWW_DIR}/
#cp ${THIS_SCRIPT_DIR}/mw-status.sh  ${WWW_DIR}/
cp ${THIS_SCRIPT_DIR}/1.html  ${WWW_DIR}/
gen_page_2 ${WWW_DIR}/2.html    
