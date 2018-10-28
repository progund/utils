#!/bin/bash

BASH_PROFILE=~/.bash_profile

if [ ! -f ${BASH_PROFILE} ]
then
    touch ${BASH_PROFILE}
fi

DEBUG=true
debug() {
    if [ "$DEBUG" = "true" ]
    then
        echo "$*"
    fi
}

alias_text()
{
    ALIAS_NAME="$1"
    ALIAS_CMD="$2"

    echo
    echo "# Juneday alias added $(date)"
    echo "alias ${ALIAS_NAME}='$ALIAS_CMD'"
    echo
}

add_alias()
{
    echo "add_alias_text $1 | $2"
    NAME="$1"
    CMD="$2"

    echo "Checking $BASH_PROFILE"
    if [ $(grep -c "alias ${NAME}" $BASH_PROFILE) -eq 0 ]
    then
        echo "Adding to $BASH_PROFILE"
        alias_text ${NAME} "${CMD}" >> $BASH_PROFILE
    else
        echo "NOT adding to $BASH_PROFILE"
    fi
}

add_alias date "gdate"

