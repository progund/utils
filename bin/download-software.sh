#!/bin/sh

#
#
# Bash script to download/update softwares used in our books
#
#
#

THIS_SCRIPT_DIR=$(dirname $0)
BASH_FUNCTIONS=${THIS_SCRIPT_DIR}/bash-functions
if [ -f ${BASH_FUNCTIONS} ]
then
    . ${BASH_FUNCTIONS}
else
    echo -n "Failed finding file: ${BASH_FUNCTIONS}. "
    echo "Bailing out..."
    exit 1
fi

determine_os
#echo "Using $OS:$DIST"

dload_sw_linux_fedora()
{
    echo "Download fedora packages"
    sudo dnf install gcc arduino valgrind java-1.8.0-openjdk curl wget \
         sqlite git cvs svn mercurial bzr emacs vim make firefox

    if [ ! -f atom.rpm ]
    then
        curl https://atom.io/download/rpm -o atom.rpm && sudo rpm -i atom.rpm
    fi
}

dload_sw_MacOS()
{
    echo "No support for downloading softare in $OS"
}

dload_sw_${OS}_${DIST}


