#!/bin/bash

SCRIPT_DIR=$(dirname $0)
THIS_SCRIPT_DIR=$SCRIPT_DIR
DATE=$(date '+%Y%m%d')
GOURCE_DEST_DIR=~/.gource-git-repos
DEST_GIT_DIR=~/.gource-git-repos/git-repos
GIT_REPOS_FILE=$GOURCE_DEST_DIR/repos-${DATE}.txt
LOG_FILE=/tmp/gource-repos.log

if [ ! -d $DEST_GIT_DIR ]
then
    mkdir -p $DEST_GIT_DIR
fi

if [ ! -f $GIT_REPOS_FILE ]
then
    $SCRIPT_DIR/../git/bin/git-repos.sh > $GIT_REPOS_FILE
fi

GIT_FUNS=$SCRIPT_DIR/../lib/stats/git-functions
if [ ! -f $GIT_FUNS ]
then
    echo "Missing git functions ($GIT_FUNS)"
    exit 2
else
    . $GIT_FUNS
fi
BASH_FUNS=$SCRIPT_DIR/bash-functions
if [ ! -f $BASH_FUNS ]
then
    echo "Missing bash functions ($BASH_FUNS)"
    exit 2
else
    . $BASH_FUNS
fi


get_repos()
{
    CNT=0
    pushd $DEST_GIT_DIR
    for repo in $(cat $GIT_REPOS_FILE)
    do
        echo $repo
        CNT=$(( $CNT + 1 ))
        if [ $CNT -gt 300 ]
        then
            echo "Too many repos, bailing out ;)"
            break
        fi
        dload_repo $repo
    done
    popd
}

log_repos()
{
    pushd $DEST_GIT_DIR
    for year in $YEARS
    do
        for month in $MONTHS
        do
            if [ $year -eq $YEAR ] && [ $month -gt $MONTH ]
            then
                echo "Uh oh, future's not so bright. Gotta wear shades"
                echo "Just kidding, we've reach reached past $YEAR-$MONTH ($year-$month is bigger)"
                break
            fi
            GLOG_DIR=gource-logs
            mkdir -p $GLOG_DIR
            # inner 
            rm -f $GLOG_DIR/$year-$month-all.txt
            for dir in $(find ./* -type d -prune | sed 's,./,,g' | grep -v $GLOG_DIR)
            do
                GIT_LOG=$GLOG_DIR/$year-$month-$dir.txt 
                echo "$year | $month | $repo"
                echo                gource --output-custom-log $GIT_LOG $dir
                echo       gource --start-date "$year-$month-01" --stop-date "$year-$month-31" --output-custom-log $GIT_LOG $dir
                gource $PERIOD --start-date "$year-$month-01" --stop-date "$year-$month-31" --output-custom-log $GIT_LOG $dir 
                if [ $? -eq 0 ]
                then
                    cat  $GIT_LOG | sort >> $GLOG_DIR/$year-$month-all.txt
                fi
            done
        done
    done
    popd
}

make_video()
{
    GIT_LOG_FOR_VIDEO=$1
    RESULTING_VIDEO=$2
    echo "MAKE VIDEO ???????????????????????????????????"
    if [ "$DEBUG" != "true" ] && [ -f $RESULTING_VIDEO ]
       then
           echo " ----- preceeding"
           echo "log ($GIT_LOG_FOR_VIDEO) to video ($RESULTING_VIDEO)"
 #          ls -al $GIT_LOG_FOR_VIDEO
#           sleep 2
           if [ ! -f $GIT_LOG_FOR_VIDEO ] 
           then
               echo " ----- missing"
               echo "log file ($GIT_LOG_FOR_VIDEO) is missing, ignoring"
               return
           fi
           if [ ! -s $GIT_LOG_FOR_VIDEO ]
           then
               echo " ----- zero size"
               echo "log file ($GIT_LOG_FOR_VIDEO) has zero size, ignoring"
               return
           fi
           echo " ----- MAKING"
           sleep 2
           gource \
               $GIT_LOG_FOR_VIDEO\
	          --highlight-users \
	          --highlight-dirs \
	          --file-extensions \
	          --hide mouse \
	          --key \
	          --stop-at-end \
	          --output-ppm-stream - \
                  -1280x720 -o - | ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf 1 -threads 0 -bf 0 $RESULTING_VIDEO
           echo "CREATED $RESULTING_VIDEO in $(pwd)"
           exit
           DEBUG=true
    else
        echo "log ($GIT_LOG_FOR_VIDEO) to video ($RESULTING_VIDEO): NOT PRODUCING"
    fi
}

do_gource()
{
    pushd $DEST_GIT_DIR
    for year in $YEARS
    do
        for month in $MONTHS
        do
            if [ $year -eq $YEAR ] && [ $month -gt $MONTH ]
            then
                echo "Uh oh, future's not so bright. Gotta wear shades"
                echo "Just kidding, we've reach reached past $YEAR-$MONTH ($year-$month is bigger)"
                break
            fi
            GLOG_DIR=gource-logs
            mkdir -p $GLOG_DIR
            # inner
            for dir in $(find ./* -type d -prune | sed 's,./,,g' | grep -v $GLOG_DIR)
            do
                VIDEO=$GOURCE_DEST_DIR/juneday-$year-$month.mp4
                if [ -f $GLOG_DIR/$year-$month-all.txt ]
                then
                    echo "Creating $VIDEO: make_video $(pwd)/$GLOG_DIR/$year-$month-all.txt $VIDEO"
                    pwd
                    ls -al $(pwd)/$GLOG_DIR/$year-$month-all.txt
                    make_video $(pwd)/$GLOG_DIR/$year-$month-all.txt $VIDEO
                else
                    echo " -------------- NOT DOING VIDEO FROM $GLOG_DIR/$year-$month-all.txt"
                fi
            done
        done
    done
    popd
}

YEAR="$(date '+%Y')"
MONTH="$(date '+%m')"
YEARS="$(seq 2016 $YEAR)"
YEARS="2016"
MONTHS="$(seq -w 1 12)"

#echo "$YEARS | $MONTHS"
#exit


get_repos
#log_repos
do_gource
