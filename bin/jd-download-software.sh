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

MacOS_MacOS_set_install_tool()
{
    if [ "$MAC_INSTALL_TOOL" != "" ]
    then
        return 
    fi

    /opt/local/bin/port version 2>/dev/null >/dev/null
    PORT_RET=$?

    /usr/local/bin/brew --version  2>/dev/null >/dev/null
    BREW_RET=$?

    if [ $PORT_RET -ne 0 ] && [ $BREW_RET -ne 0 ]
    then
        echo "*****************************************************"
        echo "*** Uh oh, neither Homebrew or MacPorts seems     *** "
        echo "*** to be installed. This means, we're not able   ***"
        echo "*** to download the required software packages    ***"
        echo "***                                               ***" 
        echo "*** WHAT TO DO NOW?                               ***" 
        echo "***                                               ***"
        echo "***    Install HomeBrew or MacPorts and try again ***"
        echo "***                                               ***"
        echo "*****************************************************"
        exit 6
    elif [ $PORT_RET -eq 0 ] && [ $BREW_RET -eq 0 ]
    then
        echo "*****************************************************"
        echo "***    Both Homebrew or MacPorts seems            ***"
        echo "*** to be installed. We're choosing to use:       ***"
        echo "***                                               ***"
        echo "***                HomeBrew                       ***"
        echo "***                                               ***" 
        echo "*****************************************************"
        MAC_INSTALL_TOOL=/usr/local/bin/brew
        MAC_INSTALL_INSTALL="/usr/local/bin/brew install"
        MAC_INSTALL_UPDATE="/usr/local/bin/brew update"
        MAC_INSTALL_UPGRADE="/usr/local/bin/brew upgrade"
    elif [ $PORT_RET -eq 0 ]
    then
        MAC_INSTALL_TOOL=/opt/local/bin/port
        MAC_INSTALL_INSTALL="/opt/local/bin/port install"
        MAC_INSTALL_UPDATE="/opt/local/bin/port selfupdate"
        MAC_INSTALL_UPGRADE="/opt/local/bin/port upgrade"
    elif [ $BREW_RET -eq 0 ]
    then
        MAC_INSTALL_TOOL=/usr/local/bin/brew
    fi
    
}

dload_sw_MacOS_MacOS()
{
    MacOS_MacOS_set_install_tool
    sudo $MAC_INSTALL_INSTALL $PKGS
    exit_on_error "$?" "Failed installing software using $MAC_INSTALL_INSTALL $PKGS"
    
}

install_atom_MacOS_MacOS()
{
    MacOS_MacOS_set_install_tool
    echo "Not installing Atom for MacOS"
}
update_os_MacOS_MacOS()
{
    MacOS_MacOS_set_install_tool
    sudo $MAC_INSTALL_UPDATE
    exit_on_error "$?" "Failed updating install tool using $MAC_INSTALL_UPDATE"
    sudo $MAC_INSTALL_UPGRADE
    exit_on_error "$?" "Failed upgrading using $MAC_INSTALL_UPGRADE"
}


dload_sw_cygwin_cygwin()
{
    echo "Dowloading for Cygwin"
    echo "Check if apt-cyg is present"
    apt-cyg --version 2>/dev/null >/dev/null
    if [ $? -ne 0 ]
    then
        echo "Downloading apt-cyg"
        curl -LJO https://rawgit.com/transcode-open/apt-cyg/master/apt-cyg -o apt-cyg
        install apt-cyg /bin
    fi

    APT_CYG=$(which apt-cyg 2>/dev/null)
    if [ "$APT_CYG" = ""  ]
    then
        echo "*****************************************************"
        echo "*** Uh oh, apt-cyg ($APT_CYG) seems to be missing ***"
        echo "*** or malfunctioning                             ***"
        echo "*** This means, we're not able to download        ***"
        echo "*** the required software packages to cygwin      ***"
        echo "***                                               ***" 
        echo "***  1. remove the file /usr/bin/ap-cyg. In Bash: ***"
        echo "***          rm /usr/bin/apt-cyg                  ***"
        echo "***     And the re-run the script                 ***"
        echo "***                                               ***"
        echo "***  2. if this is the second time you're reading ***"
        echo "***     you're most likely pissed of so,          ***"
        echo "***     calm down and                             ***"
        echo "***     ... contact the idiots at juneday         ***"
        echo "***                                               ***"
        echo "*****************************************************"
        exit 3
    fi

    test -s $APT_CYG
    RET=$?
    if [ "$RET" != "0"  ]
    then
        echo "*****************************************************"
        echo "*** Uh oh, apt-cyg seems to be of zero size       *** "
        echo "*** This means, we're not able to download        ***"
        echo "*** the required software packages to cygwin      ***"
        echo "***                                               ***" 
        echo "*** WHAT TO DO NOW?                               ***" 
        echo "***                                               ***"
        echo "***  1. remove the file /usr/bin/ap-cyg. In Bash: ***"
        echo "***          rm /usr/bin/apt-cyg                  ***"
        echo "***     And the re-run the script                 ***"
        echo "***                                               ***"
        echo "***  2. if this is the second time you're reading ***"
        echo "***     you're most likely pissed of so,          ***"
        echo "***     calm down and                             ***"
        echo "***     ... contact the idiots at juneday         ***"
        echo "***                                               ***"
        echo "*****************************************************"
        exit 4
    fi
    
    apt-cyg --version
    if [ $? -ne 0 ]
    then
        echo "*****************************************************"
        echo "*** Uh oh, apt-cyg seems to be of malfunctioning  *** "
        echo "*** This means, we're not able to download        ***"
        echo "*** the required software packages to cygwin      ***"
        echo "***                                               ***" 
        echo "*** WHAT TO DO NOW?                               ***" 
        echo "***                                               ***"
        echo "***  1. remove the file /usr/bin/ap-cyg. In Bash: ***"
        echo "***          rm /usr/bin/apt-cyg                  ***"
        echo "***     And the re-run the script                 ***"
        echo "***                                               ***"
        echo "***  2. if this is the second time you're reading ***"
        echo "***     you're most likely pissed of so,          ***"
        echo "***     calm down and                             ***"
        echo "***     ... contact the idiots at juneday         ***"
        echo "***                                               ***"
        echo "*****************************************************"
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

