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

JD_DIR=$(find ${JD_STAT_DIR}/ -type d -name "20*" | sort | tail -1)
JD_FILE=${JD_DIR}/jd-stats.json

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
echo "</body>"
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
echo "</html>"
}


#
# Copy/generate HTML files
#
cp ${THIS_SCRIPT_DIR}/index.html  ${WWW_DIR}/
gen_page_2 > ${WWW_DIR}/2.html    
