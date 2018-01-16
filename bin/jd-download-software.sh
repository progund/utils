#!/bin/bash

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
    echo "Sourcing file:  ${BASH_FUNCTIONS}"
    . ${BASH_FUNCTIONS} $*
    determine_os
else
    echo -n "Failed finding file: ${BASH_FUNCTIONS}. "
    echo "Bailing out..."
    exit 1
fi


install_atom_linux_fedora()
{
    if [ "$(dnf list atom | grep -i atom | wc -l)" != "0" ]
    then
        echo "Atom already installed"
        return 0
    fi
    

    if [ -f atom.rpm ]
    then
           rm -fr atom.rpm
    fi
    
    curl -L https://atom.io/download/rpm -o atom.rpm
    exit_on_error "$?" "Failed downloading Atom package"

    sudo rpm -i atom.rpm
    exit_on_error "$?" "Failed installing Atom package"
}

install_atom_linux_ubuntu()
{
    if [ "$(dpkg --list atom | wc -l)" != "0" ]
    then
        echo "Atom already installed"
        return 0
    fi

    if [ -f atom.rpm ]
    then
        rm -fr atom.rpm
    fi
    
    curl -L https://atom.io/download/deb -o atom.deb
    exit_on_error "$?" "Failed downloading Atom package"
    
    sudo dpkg -i atom.deb
    exit_on_error "$?" "Failed installing Atom package"
}

dload_sw_linux_fedora()
{
    echo "Download fedora packages"
    sudo dnf install -y $PKGS
    exit_on_error "$?" "Failed installing system packages"
}

dload_sw_linux_ubuntu()
{
    echo "Download ubun packages"
    sudo apt-get install -y  $PKGS
    exit_on_error "$?" "Failed installing system packages"
}

update_os_linux_ubuntu()
{
    sudo apt-get update && sudo apt-get upgrade -y
    exit_on_error "$?" "Failed upgrading system packages"
}

update_os_linux_fedora()
{
    sudo dnf update && sudo dnf upgrade -y
    exit_on_error "$?" "Failed upgrading system packages"
}

dload_sw_MacOS_MacOS()
{
    sudo port install $PKGS
}

install_atom_MacOS_MacOS()
{
    echo "Not installing Atom for MacOS"
}
update_os_MacOS_MacOS()
{
    sudo port upgrade outdated
}


dload_sw_cygwin_cygwin()
{
    echo "Dowloading for Cygwin"
    echo "Check if apt-cyg is present"
    apt-cyg --version 2>/dev/null >/dev/null
    if [ $? -ne 0 ]
    then
        echo "Downloading apt-cyg"
        lynx -source https://rawgit.com/transcode-open/apt-cyg/master/apt-cyg > apt-cyg
        install apt-cyg /bin
    fi

    APT_CYG=$(which apt-cyg)
    test -s $APT_CYG
    RET=$?
    if [ "$RET" != "0"  ]
    then
        echo "*** Uh oh, apt-cyg ($APT_CYG) seems to be of zero size *** "
        echo "***  This means, we're not able to download   ***"
        echo "*** the  required software packages to cygwin ***"
        echo "*** Contact the idiots at juneday ***"
        exit 4
    fi
    
    apt-cyg --version
    if [ $? -ne 0 ]
    then
        echo "*** Uh oh, failed downloading or installing apt-cyg *** "
        echo "***  This means, we're not able to download   ***"
        echo "*** the  required software packages to cygwin ***"
        echo "*** Contact the idiots at juneday ***"
        exit 5
    fi

    apt-cyg install $PKGS
}

install_atom_cygwin_cygwin()
{
    echo "Not installing Atom for Cygwin"
}
update_os_cygwin_cygwin()
{
    echo "Not updating for Cygwin"
}

PKG_LIST_FILE=${THIS_SCRIPT_DIR}/../etc/${DIST}.pkgs
PKGS=$(cat "${PKG_LIST_FILE}")

dload_sw_${OS}_${DIST}
install_atom_${OS}_${DIST}
update_os_${OS}_${DIST}

