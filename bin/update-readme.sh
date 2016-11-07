#!/bin/bash

#
#
# Script to update the README files in all directories in a repo
#
#   Execute and you will get 
#

GIT=false

if [ "$1" = "--git" ]
then
    GIT=true
    shift
fi

BASE_MD=$(dirname $0)/../etc/README-base.md

if [ ! -f $BASE_MD ]
then
    echo "Can not find the base markdown file '$BASE_MD'....cowardly bailing out"
    exit 1
fi

#
# debug or not
#
DEBUG_MODE=debug
DEBUG_MODE=

update_dir() {
    DIR_MD=$1/README.md
    echo
    echo "Managing dir: $1"

    echo "* Copy base md"
    if [ "$DEBUG_MODE" != "debug" ]
    then
        cp $BASE_MD $DIR_MD
    else
        echo cp $BASE_MD $DIR_MD
    fi
    if [ "$?" != "0" ]
    then
        echo "Failed copying cp $BASE_MD $DIR_MD"
        exit 1
    fi
    ADD_MD=$1/README-addition.md
    echo "* Finding additional md '$ADD_MD'"
    if [ -f $ADD_MD ]
    then
        echo "Using $ADD_MD"
        if [ "$DEBUG_MODE" != "debug" ]
        then
            echo "" >> $DIR_MD
            cat $ADD_MD >> $DIR_MD
            if [ "$?" != "0" ]
            then
                echo "Failed concatting $ADD_MD to $DIR_MD"
                exit 1
            fi
        else
            echo "cat $ADD_MD >> $DIR_MD"
        fi
    fi

    if [ "$GIT" = "true" ]
       then 
           if [ "$DEBUG_MODE" != "debug" ]
           then
               git add "$DIR_MD"
               git commit -m "Auto update (on $(hostname)) using '$0' $DIR_MD"
           else
               echo git commit -m "Auto update (on $(hostname)) using '$0' $DIR_MD"
           fi
    fi
}


for dir in $(find * -type d)
do
    update_dir $dir 
done
update_dir .


if [ "$GIT" = "true" ]
then 
    if [ "$DEBUG_MODE" != "debug" ]
    then
        git push
    else
        echo     git push
    fi
fi
