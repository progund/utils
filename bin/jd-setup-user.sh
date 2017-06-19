#!/bin/bash

SUDO=echo

if [ "$1" = "--add" ]
then
    CUR_USER="$2"
    shift
    ADD=true
else
    CUR_USER="$1"
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


THIS_SCRIPT_DIR="$(dirname $0)"
BASH_FUNCTIONS="${THIS_SCRIPT_DIR}/bash-functions"
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
        if [ "$OS" = "linux" ]
        then
            $SUDO usermod -a -G  "$g"    "$CUR_USER"
        fi
    done
}


if [ "$ADD" = "true" ]
then
    add_user
fi

# For Arduino
if [ "$OS" = "linux" ]
then
    $SUDO usermod -a -G dialout "$CUR_USER" 
fi


#
# bashrc etc
#
BASHRC="/home/$CUR_USER/.bashrc"
add_to_bashrc()
{
    echo "$*" >> "$BASHRC"
}


JUNEDAYRC="/home/$CUR_USER/.junedayrc"
JUNEDAYRC_FILE=".junedayrc"
add_to_junedayrc()
{
    echo "$*" >> "$JUNEDAYRC"
}

#
# Prevent from adding twice
#
JD_FOUND=`grep Juneday "$BASHRC" | wc -l`
if [ "$JD_FOUND" = "0" ]
then
       add_to_bashrc  "#"
       add_to_bashrc  "#"
       add_to_bashrc  "# Added by Juneday education"
       add_to_bashrc  "#"
#       add_to_bashrc  "# PATH=\${PATH}:\"$DEST_DIR/utils/bin/\""
       add_to_bashrc  "if [ -f ~/$JUNEDAYRC_FILE ] ; then .  $JUNEDAYRC_FILE; fi "
fi

# Clean .junedayrc
rm -f "$JUNEDAYRC"
add_to_junedayrc "# Juneday bash stuff "
add_to_junedayrc "# Added $(date) by $USER on $(uname -n)"
add_to_junedayrc ""
add_to_junedayrc "# C development aliases"
add_to_junedayrc "alias pgcc='gcc  -pedantic -Wconversion -Wall -Werror  -Wextra -Wstrict-prototypes'"
add_to_junedayrc "function show() { declare -f \"\$1\" || alias \"\$1\" ; }"
add_to_junedayrc ""
add_to_junedayrc "#"
add_to_junedayrc "# Functions to set the prompt differently"
add_to_junedayrc "#"
add_to_junedayrc "export SAVED_PS1=\"\$PS1\""
add_to_junedayrc "function gitprompt()    { PS1=\"\u@\h [\$(date +'%H:%M:%S')] \w \$(brname)\n # \";}"
add_to_junedayrc "function normalprompt() { export PS1=\"\$SAVED_PS1\"; }"
add_to_junedayrc "function smallprompt()  { PS1=\"# \" ;}"
add_to_junedayrc "function debianprompt()  { export PS1=\"\$DEBIAN_PS\" ;}"
add_to_junedayrc ""
add_to_junedayrc "#"
add_to_junedayrc "# Functions to 'walk' between directories"
add_to_junedayrc "#"
add_to_junedayrc "# p dir - go to a directory and put the current dir in the stack"
add_to_junedayrc "p() { pushd \"\$1\"; dirs -v ;}"
add_to_junedayrc "# o - go to the directory at the top of the stack"
add_to_junedayrc "o() { popd; dirs -v ;}"



