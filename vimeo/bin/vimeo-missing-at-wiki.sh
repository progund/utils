#!/bin/bash

SCRIPTDIR=$(dirname $0)

# file with Beaerer defined in variable VIMEO_BEARER
SETTINGS=$SCRIPTDIR/../../../utils-private/etc/vimeo.rc
if [ ! -f ${SETTINGS} ]
then
    echo "Can't find file $SETTINGS"
    exit 1
fi
. ${SETTINGS}

TODAY=$(date '+%Y%m%d')
TODAY_MIS=/tmp/vimeo-missing-${TODAY}.txt
TODAY_MIS_TMP=/tmp/vimeo-missing-${TODAY}.tmpdir

JSON_BASE=http://rameau.sandklef.com/junedaywiki-stats/

find_missing()
{
    mkdir -p ${TODAY_MIS_TMP}
    LATEST_JSON=$(curl -s $JSON_BASE | grep -B 1 "jd-complete" | head -1 | sed 's,[<>=],\n,g' | grep -A 2 href | tail -1 | sed 's,/,,g')
    curl -s $JSON_BASE/$LATEST_JSON/jd-stats.json > ${TODAY_MIS_TMP}/jd-stats.json
    cat ${TODAY_MIS_TMP}/jd-stats.json |  jq -r '.books[].chapters[].videos'  | grep https | sed -e 's,/, ,g' -e 's/[",]//g'  | awk '{print $3}' | sort -u | uniq  > ${TODAY_MIS_TMP}/in-wiki.txt

    $SCRIPTDIR/vimeo-videos.sh | sort | uniq > ${TODAY_MIS_TMP}/all.txt
    
    grep -v -f ${TODAY_MIS_TMP}/in-wiki.txt ${TODAY_MIS_TMP}/all.txt > ${TODAY_MIS_TMP}/diff.txt

    for vid in $(cat ${TODAY_MIS_TMP}/diff.txt)
    do
        echo -n "$vid: "
        curl -s -H "Authorization: Bearer $VIMEO_BEARER" "https://api.vimeo.com/videos/$vid?fields=name" | jq '.name'
    done
}

if [ ! -f $TODAY_MIS ]  || [ "$1" = "-f" ]
then
    find_missing > $TODAY_MIS
fi 

cat $TODAY_MIS
