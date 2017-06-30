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


JD_DIR=$(find ${JD_STAT_DIR}/ -type d -name "20*" 2>/dev/null | sort | tail -1)
JD_FILE=${JD_DIR}/jd-stats.json

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


if [ ! -f ${JD_FILE} ]
then
    echo "Missing log file"
    exit 1
fi



print_tag()
{
    echo -n "$1: "
    cat $JD_FILE | jq -r ".$2"
    echo "<br>"
}

gen_page_2()
{
echo "<html>"
echo "<head>"
#echo "<meta http-equiv=\"refresh\" content=\"10;index.html\"   >"
echo "</head>"
echo "<title>"
echo "Worklog for Rikard and Henrik"
echo "</title>"
echo "<body>"
echo "<center>"
echo "<h1>Stats from our wiki</h1>"
echo "<h2>"
print_tag "Number of Wiki books" "[\"book-summary\"].books"
print_tag "Number of pages in our Wiki books" "[\"book-summary\"].pages"
print_tag "Number of presentations" "[\"book-summary\"].\"uniq-presentations\""
print_tag "Number of presentation pages" "[\"book-summary\"].\"uniq-presentations-pages\""
print_tag "Number of linked videos" "[\"book-summary\"].\"uniq-videos\""
echo "</h2>"
echo "<h1>Stats from the source code use in our courses </h1>"
echo "<h2>"
print_tag "Number of public repos" "[\"git-repos\"].total"
NR_OF_LANG=$(cat $JD_FILE |  jq -r '.["source-code"]|length')
#echo "LANGS: $NR_OF_LANG"
export CNT=0
while [ $CNT -lt $NR_OF_LANG ]
do
#    echo "CNT: $CNT"
    JD_LOC=$(cat $JD_FILE | jq -r  ".[\"source-code\"][$CNT].\"lines-of-code\"")
    JD_LANG=$(cat $JD_FILE | jq -r  ".[\"source-code\"][$CNT].\"type\"")
    echo "Lines of $JD_LANG code: $JD_LOC"
    echo "<br>"
    CNT=$(( $CNT + 1 ))
done
echo "</h2>"
echo "<h1>Stats from Vimeo</h1>"
echo "<h2>"
print_tag "Number of Vimeo videos" "[\"vimeo-stats\"].\"videos\""
echo "</h2>"
echo "</center>"
echo "</body>"
echo "</html>"
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
gen_page_2 > ${WWW_DIR}/2.html    
