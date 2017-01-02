#!/bin/bash

#
#
# Bash script to install desktopn shortcuts/entries useful when using our books
#
#
#

THIS_SCRIPT_DIR=$(dirname $0)
BASH_FUNCTIONS=${THIS_SCRIPT_DIR}/bash-functions
if [ -f ${BASH_FUNCTIONS} ]
then
    echo "Sourcing file:  ${BASH_FUNCTIONS}"
    . ${BASH_FUNCTIONS}
else
    echo -n "Failed finding file: ${BASH_FUNCTIONS}. "
    echo "Bailing out..."
    exit 1
fi

determine_os
if [ $? -ne 0 ]
then
    echo "$OS:$DIST not supported"
    exit 1
fi


#
# move to common place
#

TERMINAL=x-terminal-emulator
BROWSER=x-www-browser

DESKTOP_DIR=Juneday-Education
mkdir -p ~/Desktop/${DESKTOP_DIR}


TMPL_DIR=${THIS_SCRIPT_DIR}/../templates


create_desktop_icon()
{
    export PROGRAM="$1"
    export ICON="$2"
    export NAME="$3"
    export DT_FILE=$4
    NO_TERM=$5
    DT_PATH=~/Desktop/$DT_FILE

    if [ "$NO_TERM" == "no-term" ]
    then
        USE_TERM=false
    else
        USE_TERM=true
    fi
    
    if [ ! -f $DT_PATH ]
    then
        cat ${TMPL_DIR}/template.desktop | \
            sed -e "s,__PROGRAM__,$PROGRAM,g" \
                -e "s,__ICON__,$ICON,g" \
                -e "s,__TERMINAL__,$USE_TERM,g" \
                -e "s,__NAME__,$NAME,g" \
                > $DT_PATH
           chmod a+x ~/Desktop/$DT_FILE
    fi
}

create_desktop_directory()
{
    pushd ~/Desktop/${DESKTOP_DIR}
    ln -s ~/juneday-education "./Juneday Education Repositories"
    popd
}


create_desktop_icon \
    "$TERMINAL -e $DEST_DIR/utils/bin/jd-download-software.sh" \
    "" \
    "Update system software" \
    "${DESKTOP_DIR}/jd-update-sw.desktop"

create_desktop_icon \
    "$TERMINAL -e $DEST_DIR/utils/bin/jd-dload-techbooks.sh" \
    "" \
    "Update educational repositories" \
    "${DESKTOP_DIR}/jd-update-repos.desktop"

create_desktop_icon \
    "$TERMINAL -e $DEST_DIR/utils/bin/jd-set-mime.sh" \
    "" \
    "Set Atom as editor" \
    "${DESKTOP_DIR}/jd-set-mime.desktop"

create_desktop_icon \
    "$BROWSER http://virt08.itu.chalmers.se/mediawiki/" \
    "" \
    "Juneday Education wiki" \
    "${DESKTOP_DIR}/jd-wiki.desktop" \
    "no-term"




#create_desktop_directory
