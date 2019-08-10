#!/bin/bash

LOG_FILE=/tmp/db-html.log

DB_FILE=$1
if [ ! -f $DB_FILE ] || [ -z $DB_FILE ]
then
    echo "Can't open \"$DB_FILE\""
    echo "Usage: $(basename $0) dbfile"
    exit 1
fi

init_html()
{
    echo "<html>" >> $1
    echo "<body>" >> $1
}

end_html()
{
    echo "</body>" >> $1
    echo "</html>" >> $1
}
sql()
{
    log "SQL: $* [using sqlite3 $DB]" 
    echo -e "$*" | sqlite3 $DB
}

log()
{
    echo "$*" >> $LOG_FILE
}

log "---=== $(date) ===---"

echo
echo "Reading database $DB_FILE"
echo "========================================================"

db=$DB_FILE
echo "Database $db:"
export DB=$db
rm -f ${db}.html
rm -f ${db}.txt
init_html  ${db}.html

for tbl in $(sql ".schema" | grep -v android_metadata | grep "CREATE[ ]*TABLE" | sed -e 's,(, (,g' -e 's,[ ]*IF[ ]*NOT[ ]*EXISTS[ ]*, ,g' -e "s,',,g" |  awk '{ print $3}')
do
    echo " * $tbl"
    log "Reading from $DB::$tbl"
    echo "<table border=1>  " >> ${db}.html
    echo "<h1>Table: $tbl</h1>" >> ${db}.html
    SQL_CMD=".header on\n.mode html\nSELECT * FROM $tbl"
    sql "$SQL_CMD" >>  ${db}.html
    echo "</table>  " >> ${db}.html

    SQL_CMD=".mode ascii\nSELECT * FROM $tbl"
    sql "$SQL_CMD" >> ${db}.txt

done
end_html  ${db}.html
