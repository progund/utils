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
MONTH_AGO=$(date --date "-30 days" '+%Y%m%d')

#JD_DIR=$(find ${JD_STAT_DIR}/ -type d -name "20*" 2>/dev/null | sort | tail -1)
JD_DIR=${JD_STAT_DIR}/$TODAY
JD_FILE=${JD_DIR}/jd-stats.json
JD_WEEK_AGO_FILE=${JD_STAT_DIR}/$WEEK_AGO/jd-stats.json
JD_MONTH_AGO_FILE=${JD_STAT_DIR}/$MONTH_AGO/jd-stats.json

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
#    echo writin to: $TOFILE
}

get_tag()
{
    
    cat $JD_FILE | jq -r ".$1"
}

get_week_tag()
{
    NOW=$(cat $JD_FILE | jq -r ".$1")
    THEN=$(cat $JD_WEEK_AGO_FILE | jq -r ".$1")
    echo $(( $NOW - $THEN ))
}

get_month_tag()
{
    NOW=$(cat $JD_FILE | jq -r ".$1")
    THEN=$(cat $JD_MONTH_AGO_FILE | jq -r ".$1")
    echo $(( $NOW - $THEN ))
}


get_lang_loc_impl()
{
    export JSON_FILE=$1
    export lang="$2"

    cat $JSON_FILE |  jq -r ."\"source-code\"[]|{\"lines-of-code\","type"}|select(.type==\"$lang\")|{\"lines-of-code\"}|.[]"
}

get_lang_loc()
{
    get_lang_loc_impl $JD_FILE "$1"

#    cat $JD_FILE |  jq -r ."\"source-code\"[]|{\"lines-of-code\","type"}|select(.type==\"$lang\")|{\"lines-of-code\"}|.[]"
}

get_wlang_loc()
{
    get_lang_loc_impl $JD_WEEK_AGO_FILE "$1"
#    export lang=$1
    
#    cat $JD_WEEK_AGO_FILE |  jq -r ."\"source-code\"[]|{\"lines-of-code\","type"}|select(.type==\"$lang\")|{\"lines-of-code\"}|.[]"
}

get_mlang_loc()
{
    get_lang_loc_impl $JD_MONTH_AGO_FILE "$1"
#    export lang=$1
    
#    cat $JD_WEEK_AGO_FILE |  jq -r ."\"source-code\"[]|{\"lines-of-code\","type"}|select(.type==\"$lang\")|{\"lines-of-code\"}|.[]"
}

gen_page_2()
{
    declare -A JD_LOCS
    TOFILE=$1
    export LOC_JAVA=$(get_lang_loc "Java")
    export LOC_BASH=$(get_lang_loc "Bash")
    export WLOC_JAVA=$(get_wlang_loc "Java")
    export WLOC_BASH=$(get_wlang_loc "Bash")
    export MLOC_JAVA=$(get_mlang_loc "Java")
    export MLOC_BASH=$(get_mlang_loc "Bash")
    export BOOKS=$(get_tag "[\"book-summary\"].books")
    export BOOKS=$(get_tag "[\"book-summary\"].books")
    export PAGES=$(get_tag "[\"book-summary\"].pages")
    export WPAGES=$(get_tag "[\"wiki-stats\"].\"content-pages\"")
    export UNIQ_PRES=$(get_tag "[\"book-summary\"].\"uniq-presentations\"")
    export UNIQ_PRES_PAGES=$(get_tag "[\"book-summary\"].\"uniq-presentations-pages\"")
    export UNIQ_VIDS=$(get_tag "[\"book-summary\"].\"uniq-videos\"")
    export PUBLIC_REPOS=$(get_tag "[\"git-repos\"].total")
    export NR_OF_LANG=$(get_tag "[\"source-code\"]|length")
    #tofile "LANGS: $NR_OF_LANG"
    export CNT=0
    while [ $CNT -lt $NR_OF_LANG ]
    do
        #    tofile "CNT: $CNT"
        export JD_LANG=$(get_tag "[\"source-code\"][$CNT].type")
        export JD_LOC=$(get_tag "[\"source-code\"][$CNT].\"lines-of-code\"")
        JD_LOCS[$JD_LANG]=$JD_LOC
        echo "LANG: { $JD_LANG | $JD_LOC | $CNT } =>  ${JD_LOCS[Java]}"
        CNT=$(( $CNT + 1 ))
    done
    
    export W_PAGES=$(get_week_tag "[\"book-summary\"].pages")
    export W_WPAGES=$(get_week_tag "[\"wiki-stats\"].\"content-pages\"")
    export W_PRES=$(get_week_tag "[\"book-summary\"].\"uniq-presentations\"")
    export W_VIDS=$(get_week_tag "[\"vimeo-stats\"].videos")

    export M_PAGES=$(get_month_tag "[\"book-summary\"].pages")
    export M_WPAGES=$(get_month_tag "[\"wiki-stats\"].\"content-pages\"")
    export M_PRES=$(get_month_tag "[\"book-summary\"].\"uniq-presentations\"")
    export M_VIDS=$(get_month_tag "[\"vimeo-stats\"].videos")

    echo "java: $LOC_JAVA | $WLOC_JAVA | $MLOC_JAVA"
    
    export LOC_JAVA=${JD_LOCS[Java]}

    export WLOC_JAVA=$(( $LOC_JAVA - $WLOC_JAVA))
    export WLOC_BASH=$(( $LOC_BASH - $WLOC_BASH))
    
    export MLOC_JAVA=$(( $LOC_JAVA - $MLOC_JAVA))
    export MLOC_BASH=$(( $LOC_BASH - $MLOC_BASH))
    
    cat $THIS_SCRIPT_DIR/2.tmpl | sed \
        -e "s,__NR_WIKI_BOOKS__,$BOOKS,g" \
        -e "s,__NR_PRESENTATIONS__,$UNIQ_PRES,g" \
        -e "s,__NR_PRESENTATION_PAGES__,$UNIQ_PRES_PAGES,g" \
        -e "s,__NR_PAGES__,$PAGES,g" \
        -e "s,__NR_LINKED_VIDEOS__,$UNIQ_VIDS,g" \
        -e "s,__NR_PUBLIC_REPOS__,$PUBLIC_REPOS,g" \
        -e "s,__LOC_JAVA__,${JD_LOCS[Java]},g" \
        -e "s,__LOC_C__,${JD_LOCS[C]},g" \
        -e "s,__LOC_BASH__,${JD_LOCS[Bash]},g" \
        -e "s,__NR_VIMEO_VIDEOS__,$UNIQ_VIDS,g" \
        -e "s,__NR_WEEKLY_PAGES__,$W_PAGES,g" \
        -e "s,__NR_WEEKLY_WPAGES__,$W_WPAGES,g" \
        -e "s,__WEEKLY_BASH_LOC__,$WLOC_BASH,g" \
        -e "s,__WEEKLY_JAVA_LOC__,$WLOC_JAVA,g" \
        -e "s,__NR_WEEKLY_PRESENTATIONS__,$W_PRES,g" \
        -e "s,__WDATE__,$WEEK_AGO,g" \
        -e "s,__NR_WEEKLY_VIDEOS__,$W_VIDS,g" \
        -e "s,__NR_MONTHLY_PAGES__,$M_PAGES,g" \
        -e "s,__NR_MONTHLY_WPAGES__,$M_WPAGES,g" \
        -e "s,__MONTHLY_BASH_LOC__,$MLOC_BASH,g" \
        -e "s,__MONTHLY_JAVA_LOC__,$MLOC_JAVA,g" \
        -e "s,__NR_MONTHLY_PRESENTATIONS__,$M_PRES,g" \
        -e "s,__MDATE__,$MONTH_AGO,g" \
        -e "s,__NR_MONTHLY_VIDEOS__,$M_VIDS,g" \
        > $TOFILE

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
