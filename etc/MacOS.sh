#!/bin/bash

BASHRC=~/.bashrc

DEBUG=true
debug() {
    if [ "$DEBUG" = "true" ]
    then
        echo "$*"
    fi
}

alias_text()
{
    echo "alias_text() $1 | $2"
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

    echo "Checking $BASHRC"
    if [ $(grep -c "alias ${NAME}" $BASHRC) -eq 0 ]
    then
        echo "Adding to $BASHRC"
        alias_text ${NAME} "${CMD}" >> $BASHRC
    else
        echo "NOT adding to $BASHRC"
    fi
}

add_alias date "gdate"

