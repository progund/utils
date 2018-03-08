#!/bin/bash

THIS_SCRIPT_DIR=$(dirname $0)
BASH_FUNCTIONS=${THIS_SCRIPT_DIR}/bash-functions
if [ -f ${BASH_FUNCTIONS} ]
then
    echo "Sourcing file:  ${BASH_FUNCTIONS}"
    . ${BASH_FUNCTIONS} $*
    determine_os
else
    echo -n "Failed finding file: ${BASH_FUNCTIONS}. "
    echo "Bailing out..."
    exit 1
fi

source_file ${THIS_SCRIPT_DIR}/settings

if [ "$OS" = "MacOS" ]
then
    MacOS_MacOS_set_install_tool
    if [ "$MAC_INSTALL_TOOL" != "" ]
    then
        PKG_LIST_FILE=${THIS_SCRIPT_DIR}/../etc/${DIST}-${MAC_INSTALL_TOOL}.pkgs
    else
        echo ".... can't find a package manager"
        echo "****************************************"
        echo "***  Information about your system  ***"
        echo "***    OS:   $OS  "
        echo "***    DIST: $DIST "
        echo "***    pwd:  $(pwd)"
        echo "***    date: $(date)"
        echo "****************************************"
        exit 12
    fi
else
    PKG_LIST_FILE=${THIS_SCRIPT_DIR}/../etc/${DIST}.pkgs
fi

PKG_VERFICATION_NAMES_COMMON=${THIS_SCRIPT_DIR}/../etc/verification-common.pkgs
V_PACKAGES=$(cat $PKG_VERFICATION_NAMES_COMMON)


PKG_VERFICATION_NAMES_DIST=${THIS_SCRIPT_DIR}/../etc/verification-${DIST}.pkgs
if [ -f $PKG_VERFICATION_NAMES_DIST ]
then
    V_PACKAGES="$V_PACKAGES $(cat $PKG_VERFICATION_NAMES_DIST)"
fi

echo "Verifying packages"
for pkg in $V_PACKAGES
do
    echo -n " * $pkg"
    which $pkg 2> /dev/null > /dev/null
    RET=$?
#    echo "RET: $RET"
    if [ $RET -eq 0 ]
    then
        echo " OK"
    else
        echo " failed"
    fi
done
