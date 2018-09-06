#!/bin/bash

TMP_DIR=/tmp/juneday-tmp/$$

mkdir -p ${TMP_DIR}
cd       ${TMP_DIR}

dload()
{
    which curl 2>/dev/null
    CURL_RET=$?
    
    which wget 2>/dev/null
    WGET_RET=$?
    
    if [ $CURL_RET -eq 0 ]
    then
        curl -L https://github.com/progund/utils/archive/master.zip -o master.zip
    elif [ $WGET_RET -eq 0 ]
    then
        wget https://github.com/progund/utils/archive/master.zip 
    else
        echo "Failed finding tool to download"
        exit 1
    fi
}


dload

unzip master.zip
if [ $? -ne 0 ]
then
    echo "Failed unpacking master.zip"
    exit 1
fi

cd utils-master
if [ $? -ne 0 ]
then
    echo "Failed entering utils-master directory"
    exit 2
fi

#
# Pass command line arguments to setup script (typically --full)
#
bin/jd-setup.sh $*
