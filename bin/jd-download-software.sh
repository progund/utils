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


while [ "$*" != "" ]
do
    case "$1" in
        "--course")
            COURSE=$2
            shift
            ;;
        *)
            echo "SYNTAX ERROR: $1"
            exit 13
            ;;
    esac
    shift
done



install_atom_linux_fedora()
{
    if [ "$(dnf list atom 2>/dev/null | grep -i atom | wc -l)" != "0" ]
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
    $MAC_INSTALL_INSTALL $PKGS
    exit_on_error "$?" "Failed installing software using $MAC_INSTALL_INSTALL $PKGS"
    
}

install_atom_MacOS_MacOS()
{
    echo "Not installing Atom for MacOS"
}
update_os_MacOS_MacOS()
{
    $MAC_INSTALL_UPDATE
    exit_on_error "$?" "Failed updating install tool using $MAC_INSTALL_UPDATE"
    $MAC_INSTALL_UPGRADE
    RET=$?
    if [ "$MAC_INSTALL_TOOL" = "MacPorts" ]
    then
        echo "dicard exit code check on since MAC_INSTALL_TOOL ($MAC_INSTALL_TOOL) = MacPorts"
        # For some reason MacPorts upgrade outdated exits with 1 if no packages were updated ...
    else
        exit_on_error "$RET" "Failed upgrading using $MAC_INSTALL_UPGRADE"
    fi
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
    for pkg in $PKGS
    do
        echo "Installing $pkg"
        apt-cyg install $pkg
    done
}

install_atom_cygwin_cygwin()
{
    echo "Not installing Atom for Cygwin"
}
update_os_cygwin_cygwin()
{
    echo "Not updating for Cygwin"
}


if [ "$OS" = "MacOS" ]
then
    MacOS_MacOS_set_install_tool
    if [ "$MAC_INSTALL_TOOL" != "" ]
    then
        PKG_LIST_FILE=${THIS_SCRIPT_DIR}/../etc/${DIST}-${MAC_INSTALL_TOOL}.pkgs
        COURSE_PKG_LIST_FILE=${THIS_SCRIPT_DIR}/../etc/${COURSE}/${DIST}-${MAC_INSTALL_TOOL}.pkgs
    else
        echo ".... can't find a package manager"
        echo "****************************************"
        echo "***  Information about your system  ***"
        echo "***    OS:   $OS  "
        echo "***    DIST: $DIST "
        echo "***    pwd:  $(pwd)"
        echo "***    date: $(date)"
        echo "****************************************"
        exit 12
    fi
else
    PKG_LIST_FILE=${THIS_SCRIPT_DIR}/../etc/${DIST}.pkgs
    COURSE_PKG_LIST_FILE=${THIS_SCRIPT_DIR}/../etc/${COURSE}/${DIST}.pkgs
fi
if [ ! -f ${PKG_LIST_FILE} ]
then
    echo ".... can't find a list of files "
    echo "for your package manager (and possibly course)"
    echo "****************************************"
    echo "***  Information about your system  ***"
    echo "***    OS:       $OS  "
    echo "***    DIST:     $DIST "
    echo "***    pwd:      $(pwd)"
    echo "***    date:     $(date)"
    echo "***    PKG file: ${PKG_LIST_FILE}"
    echo "***    Course PKG file: ${SOURCE_PKG_LIST_FILE}"
    echo "****************************************"
    exit 18
fi
PKGS=$(cat "${PKG_LIST_FILE} ${COURSE_PKG_LIST_FILE}"  )

echo "****************************************"
echo "***  Information about your system  ***"
echo "***    OS:       $OS  "
echo "***    DIST:     $DIST "
echo "***    Course:   $COURSE  (if unset a generic set of packages will be installed)"
echo "***    pwd:      $(pwd)"
echo "***    date:     $(date)"
echo "***    PKG file: ${PKG_LIST_FILE}"
echo "***    CoursePKG file: ${COURSE_PKG_LIST_FILE}"
echo "***    Packages: ${PKGS}"
echo "****************************************"
sleep 2
echo "* Download software"
dload_sw_${OS}_${DIST}
echo "* Install Atom (if possible and needed)"
install_atom_${OS}_${DIST}
echo "* Update OS (if possible and needed)"
update_os_${OS}_${DIST}
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo "Juneday script $0 has finished installing/updating"
echo "All went well, so take a deep breath and start hacking"
echo ""
echo ""
echo ""
echo ""
echo ""
echo "             Happy hacking!"
echo ""
echo ""
echo ""
echo ""
echo ""
exit 0
