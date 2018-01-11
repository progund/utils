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

#
# internal
#
GLOG_DIR=gource-logs
GOURCE_OPTIONS="--seconds-per-day 2   --highlight-users \
	          --highlight-dirs    --file-extensions --hide mouse --key \
	          --stop-at-end --output-ppm-stream - -1280x720"
FFMPEG_OPTIONS=" -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf 1 -threads 0 -bf 0 "
get_repos()
{
#    if [ ! -f $GIT_REPOS_FILE ]
 #   then
        $SCRIPT_DIR/../git/bin/git-repos.sh > $GIT_REPOS_FILE
  #  fi


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
    echo "Creating log for: "
    for year in $YEARS
    do
        echo "  year: $year "
        for month in $MONTHS
        do
            echo "  year: $year | month: $month"
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
                echo -n "$dir "
                GIT_LOG=$GLOG_DIR/$year-$month-$dir.txt
 #               echo                gource --output-custom-log $GIT_LOG $dir
  #              echo       gource --start-date "$year-$month-01" --stop-date "$year-$month-31" --output-custom-log $GIT_LOG $dir
                gource --start-date "$year-$month-01" --stop-date "$year-$month-31" --output-custom-log $GIT_LOG $dir 2>/dev/null
                if [ $? -eq 0 ]
                then
                    cat  $GIT_LOG  >> $GLOG_DIR/$year-$month-all.txt
                fi
            done
            echo
        done
    done
    mv $GLOG_DIR/$year-$month-all.txt $GLOG_DIR/$year-$month-all-2.txt
    sort $GLOG_DIR/$year-$month-all-2.txt >  $GLOG_DIR/$year-$month-all.txt

    popd
}

make_video()
{
    GIT_LOG_FOR_VIDEO=$1
    RESULTING_VIDEO=$2
    echo "MAKE VIDEO ???????????????????????????????????"
    if [ "$DEBUG" != "true" ] && [ ! -f $RESULTING_VIDEO ]
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
           gource \
               $GIT_LOG_FOR_VIDEO $GOURCE_OPTIONS -o - \
               | ffmpeg $FFMPEG_OPTIONS $RESULTING_VIDEO
           echo "CREATED $RESULTING_VIDEO in $(pwd)"
           exit
           DEBUG=true
    else
        echo "log ($GIT_LOG_FOR_VIDEO) to video ($RESULTING_VIDEO): NOT PRODUCING"
        echo "DEBUG: $DEBUG | RESULTING_VIDEO: $RESULTING_VIDEO"
        if [ "$DEBUG" != "true" ] ; then echo FIRST; fi
        if [ -f $RESULTING_VIDEO ]; then echo LATTER; fi
    fi
}

do_gource_date()
{
    START_DATE=$1
    STOP_DATE=$2
    pushd $DEST_GIT_DIR

    mkdir -p $GLOG_DIR
    # inner 
    GIT_LOG_ALL=$GLOG_DIR/custom-${START_DATE}-${STOP_DATE}-all.txt 
    rm -f $GIT_LOG_ALL
    for dir in $(find ./* -type d -prune | sed 's,./,,g' | grep -v $GLOG_DIR)
    do
        echo -n "Creating logs for"
        echo -n " $dir | ${START_DATE} | ${STOP_DATE} | $GIT_LOG"
        GIT_LOG=$GLOG_DIR/custom-${START_DATE}-${STOP_DATE}-$dir.txt 
        gource --start-date "${START_DATE}" --stop-date "${STOP_DATE}" --output-custom-log $GIT_LOG $dir 2>/dev/null
        if [ $? -eq 0 ]
        then
            echo " OK"
            cat  $GIT_LOG  >> $GIT_LOG_ALL
            echo ls -al $GIT_LOG
        else
            echo " FAIL"
        fi
    done

    mv $GIT_LOG_ALL $GIT_LOG_ALL.tmp
    cat $GIT_LOG_ALL.tmp | sort > $GIT_LOG_ALL
    VIDEO=$GOURCE_DEST_DIR/juneday-$START_DATE-$STOP_DATE.mp4
    make_video $(pwd)/$GIT_LOG_ALL $VIDEO

    popd
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
            mkdir -p $GLOG_DIR
            # inner
            for dir in $(find ./* -type d -prune | sed 's,./,,g' | grep -v $GLOG_DIR)
            do
                VIDEO=$GOURCE_DEST_DIR/juneday-$year-$month.mp4
                if [ -f $GLOG_DIR/$year-$month-all.txt ]
                then
                    echo "Creating $VIDEO: make_video $(pwd)/$GLOG_DIR/$year-$month-all.txt $VIDEO"
                    pwd
#                    ls -al $(pwd)/$GLOG_DIR/$year-$month-all.txt
                    make_video $(pwd)/$GLOG_DIR/$year-$month-all.txt $VIDEO
                else
                    echo " -------------- NOT DOING VIDEO FROM $GLOG_DIR/$year-$month-all.txt"
                fi
            done
        done
    done
    popd
}

usage()
{
    PROG_NAME=$(basename $0)
    echo "NAME"
    echo "    $PROG_NAME - create videos from activities in multiple repositories"
    echo ""
    echo "SYNOPSIS"
    echo "    $PROG_NAME [OPTION]"
    echo ""
    echo "DESCRIPTION"
    echo ""
    echo "OPTIONS"
    echo ""
    echo "    --get-source, -gs - only get source code repositories"
    echo "    --create-log, -cl - create log for use when creating videos"
    echo "    --create-video, -cv - create video from repo activities"
    echo "    --start-date <date>  - create videos from date "
    echo "    --stop-date <date> - create videos until date "
    echo "    --help, -h - prints this message "
    echo ""
    echo "EXAMPLES"
    echo ""
}

YEAR="$(date '+%Y')"
MONTH="$(date '+%m')"
START_YEAR=2016
YEARS="$(seq $START_YEAR $YEAR)"
#YEARS="2016"
MONTHS="$(seq -w 1 12)"

while [ "$1" != "" ]
do
    case "$1" in
        "--get-source"|"-gs")
            get_repos
            exit 0
            break
            ;;
        "--create-log"|"-cl")
            log_repos
            exit 0
            break;
            ;;
        "--create-video"|"-cv")
            CREATE_VIDEO=true
            ;;
        "--start-date")
            START_DATE=$2
            shift
            ;;
        "--stop-date")
            STOP_DATE=$2
            shift
            ;;
        "--help"|"-h")
            usage
            exit 0
            ;;
        *)
            echo "SYNTAX ERROR"
            exit 13
            ;;
    esac
    shift
done


if [ "$CREATE_VIDEO" = "true" ]
then
    echo "$START_DATE | $STOP_DATE "
    if [ "$START_DATE" != "" ] && [ "$STOP_DATE"  != "" ] 
    then
        do_gource_date $START_DATE $STOP_DATE 
    elif [ "$START_DATE"  != "" ]
    then
        do_gource_date $START_DATE $(date '+%Y-%m-%d')
    elif [ "$STOP_DATE"  != "" ]
    then
        do_gource_date "${START_YEAR}-01-01" $STOP_DATE
    else
        do_gource 
    fi
           
else
    echo "Missing directive, nothing to do...."
    usage
    exit 1
fi
