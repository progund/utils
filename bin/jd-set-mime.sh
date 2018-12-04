#!/bin/bash

#
#
# Bash script to download/update our books
#
#
#

THIS_SCRIPT_DIR=$(dirname $0)
BASH_FUNCTIONS=${THIS_SCRIPT_DIR}/bash-functions
if [ -f ${BASH_FUNCTIONS} ]
then
    . ${BASH_FUNCTIONS} $*
else
    echo -n "Failed finding file: ${BASH_FUNCTIONS}. "
    echo "Bailing out..."
    exit 1
fi



show_mime()
{
    FT=$1
    echo -n "Filetype: $FT   "
    xdg-mime  query default $FT
}


#show_mime text/x-csrc 
#show_mime text/x-chdr 
#show_mime text/x-java

set_mime()
{
    Q=$1
    MIME=$2
    if [ "$(xdg-mime query default $MIME | grep -i atom | wc -l)" = "0" ]
    then
        ask_question   "$Q"
        if [ "$RET" = "0" ]
        then
            xdg-mime  default atom.desktop $MIME
        fi
    fi
}


set_mime "Do you want to set Atom as your default editor for C files?"         "text/x-csrc"
set_mime "Do you want to set Atom as your default editor for C header files?"  "text/x-chdr"
set_mime "Do you want to set Atom as your default editor for Java?"            "text/x-java"

