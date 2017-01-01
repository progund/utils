#!/bin/bash

if [ "$1" = "--add" ]
then
    CUR_USER=$2
    shift
    ADD=true
else
    CUR_USER=$USER
    ADD=false
fi
shift

if [ "$CUR_USER" = "" ]
then
    echo -n "Supply user name: "
    read username
    echo -n "Supply real name: "
    read realname
fi


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



add_user()
{
    echo "Adding new user"
    #
    #
    #
    if [ "$CUR_USER" = "" ]
    then
        echo "User name missing"
        exit 1
    fi
    
    GROUPSTOADD="adm cdrom sudo dip plugdev lpadmin sambashare "
    SUDO=echo
    
    $SUDO adduser   "$CUR_USER" 
    $SUDO addgroup "$CUR_USER"
    $SUDO usermod -a -G "$CUR_USER" "$CUR_USER"
    for g in $GROUPSTOADD
    do
        $SUDO usermod -a -G "$CUR_USER" "$g"    
    done
}


if [ "$ADD" = "true" ]
then
    add_user
fi

# For Arduino
$SUDO usermod -a -G "$CUR_USER" dialout


#
# bashrc
# 
echo "PATH=$${PATH}:$DEST_DIR/utils/bin/"
