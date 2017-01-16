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
    sudo dnf install -y gcc arduino valgrind java-1.8.0-openjdk curl wget \
         sqlite git cvs svn mercurial bzr emacs vim make firefox check  \
         gdb zip unzip splint p7zip python python3 rsync
    exit_on_error "$?" "Failed installing system packages"
}

dload_sw_linux_ubuntu()
{
    echo "Download ubun packages"
    sudo apt-get install -y gcc arduino valgrind openjdk-8-jdk curl wget \
         sqlite git cvs subversion mercurial bzr emacs vim make firefox check \
         gdb splint p7zip python python3 rsync
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
    echo "Not dowloading for MacOS"
}

install_atom_MacOS_MacOS()
{
    echo "Not installing Atom for MacOS"
}
update_os_MacOS_MacOS()
{
    echo "Not updating for MacOS"
}


dload_sw_Cygwin_Cygwin()
{
    echo "Dowloading for Cygwin"
    apt-cyg --version
    if [ $? -ne 0 ]
    then
        lynx -source rawgit.com/transcode-open/apt-cyg/master/apt-cyg > apt-cyg
        install apt-cyg /bin
    fi

    apt-cyg install gcc-core git cvs mercurial subversion curl wget perl-LWP-Protocol-https make emacs sqlite3 check gdb indent zip splint unzip p7zip python3 perl bc openssh rsync
    
}

install_atom_Cygwin_Cygwin()
{
    echo "Not installing Atom for Cygwin"
}
update_os_Cygwin_Cygwin()
{
    echo "Not updating for Cygwin"
}


dload_sw_${OS}_${DIST}
install_atom_${OS}_${DIST}
update_os_${OS}_${DIST}

