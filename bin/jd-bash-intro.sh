#!/bin/bash

TMP_DIR=/tmp/juneday-tmp/$$

mkdir -p ${TMP_DIR}
cd       ${TMP_DIR}

BOOTSTRAP_SCRIPT=jd-bootstrap.sh

dload()
{
    which curl 2>/dev/null
    CURL_RET=$?
    
    which wget 2>/dev/null
    WGET_RET=$?
    
    if [ $CURL_RET -eq 0 ]
    then
        curl -L https://raw.githubusercontent.com/progund/utils/master/bin/${BOOTSTRAP_SCRIPT} -o ${BOOTSTRAP_SCRIPT}
    elif [ $WGET_RET -eq 0 ]
    then
        wget https://raw.githubusercontent.com/progund/utils/master/bin/${BOOTSTRAP_SCRIPT}
    else
        echo "Failed finding tool to download"
        exit 1
    fi
    
    if [ ! -f ${BOOTSTRAP_SCRIPT} ]
    then
        echo "Failed to download ${BOOTSTRAP_SCRIPT}"
        exit 2
    fi
    chmod u+x jd-bootstrap.sh
}


dload

#
# The additional argument to --course must be located at utils/etc/ in reop https://github.com/progund/utils
#
./${BOOTSTRAP_SCRIPT} --course bash-intro $*


