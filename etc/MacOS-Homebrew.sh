#!/bin/bash

BASHRC=~/.bashrc

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
    NAME="$1"
    CMD="$2"

    if [ $(grep -c "alias ${NAME}" $BASHRC) -ne 0 ]
    then
        alias_text ${NAME} "${CMD}" 
    fi
}

add_alias date "gdate"

