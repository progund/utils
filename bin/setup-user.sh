#!/bin/bash

SUDO=echo

if [ "$1" = "--add" ]
then
    CUR_USER=$2
    shift
    ADD=true
else
    CUR_USER=$1
    ADD=false
fi
shift

if [ "$CUR_USER" = "" ]
then
    CUR_USER=$USER
    #    echo -n "Supply user name: "
    #    read username
    #    echo -n "Supply real name: "
    #    read realname
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
    
    $SUDO adduser   "$CUR_USER" 
    $SUDO addgroup "$CUR_USER"
    $SUDO usermod -a -G "$CUR_USER" "$CUR_USER"
    for g in $GROUPSTOADD
    do
        $SUDO usermod -a -G  "$g"    "$CUR_USER"
    done
}


if [ "$ADD" = "true" ]
then
    add_user
fi

# For Arduino
$SUDO usermod -a -G dialout "$CUR_USER" 


#
# bashrc etc
#
add_to_bashrc()
{
    echo "$*" >> /home/$CUR_USER/.bashrc
}
add_to_junedayrc()
{
    echo "$*" >> /home/$CUR_USER/.junedayrc
}

#
# Prevent from adding twice
#
if [ "$(grep Juneday /home/$CUR_USER/.bashrc | wc -l)" = "0" ]
   then
       add_to_bashrc  "#"
       add_to_bashrc  "#"
       add_to_bashrc  "# Added by Juneday education"
       add_to_bashrc  "#"
       add_to_bashrc  "#"
       add_to_bashrc  "PATH=\${PATH}:$DEST_DIR/utils/bin/"
       add_to_bashrc  "if [ -f ~/.junedayrc ] ; then .  ~/.junedayrc; fi "
fi
add_to_junedayrc "# Juneday bash stuff"
add_to_junedayrc "# "
add_to_junedayrc "# C development aliases"
add_to_junedayrc "alias pgcc='gcc  -pedantic -Wconversion -Wall -Werror  -Wextra -Wstrict-prototypes'"

