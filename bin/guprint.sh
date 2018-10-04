#!/bin/bash

ACCOUNT_NAME=$1

exit_on_error()
{
    if [ "$1" != "0" ]
    then
        if [ "$2" != "" ]
        then
            echo "$2"
            echo "return value: $1"
            exit $1
        else
            echo "Failure"
            echo "return value: $1"
            exit $1
        fi
    fi
}

if [ "$(uname  | grep -ic linux)" != "0" ] 
then
    OS=linux
elif [ "$(uname  | grep -ic darwin)" != "0" ]
then
    OS=macos
else
    echo "This script only supports GNU/Linux and MacOS"
    exit 1
fi

if [ $OS = "linux" ] 
then
    if [ -f /etc/fedora-release ]
    then
	DIST=fedora
    elif [ -f /etc/fedora-release ]
    then
	DIST=redhat
    elif [ -f /etc/os-release ]
    then
	if [ "$( grep NAME /etc/os-release | grep -i -c ubuntu)" != "0" ]
	then
            DIST=ubuntu
	else
            DIST=debian
	fi
    else
	echo "UNSUPPORTED GNU/Linux distribution"
	exit 2
    fi
else
    :
fi

cups_start() {
    if [ "$OS" = "linux" ]
    then
        if [ "$DIST" = "fedora" ]
        then
	    sudo service cups start
        else
            # non fedora => ubuntu or debian (otherwise an earlier error)
	sudo /etc/init.d/cups start
        fi
    else
        # macos
        sudo launchctl start org.cups.cupsd
    fi
}

cups_stop() {
    if [ "$OS" = "linux" ]
    then
        if [ "$DIST" = "fedora" ]
        then
	    sudo service cups stop
        else
            # non fedora => ubuntu or debian (otherwise an earlier error)
	sudo /etc/init.d/cups stop
        fi
    else
        # macos
        sudo launchctl stop org.cups.cupsd
    fi
}

echo "Requesting sudo permissions"
sudo ls >/dev/null 2>/dev/null
exit_on_error $? "Failed getting sudo permissions"
echo
echo "Got sudo permissions.... let's go"
echo 
TMP_DIR=/tmp/guprint-$$

STR_SIZE=30
printf "%-${STR_SIZE}s"  "Create tmp dir: "
mkdir $TMP_DIR
exit_on_error $? "Failed creating tmp dir ($TMP_DIR)"
echo " OK"

printf "%-${STR_SIZE}s" "Enter tmp dir: "
cd $TMP_DIR
exit_on_error $? "Failed entering tmp dir ($TMP_DIR)"
echo " OK"

printf "%-${STR_SIZE}s"  "Download drivers: "
DRIVERS_TAR_GZ=Gu-print.tar.gz
DRIVERS_URL=http://wiki.juneday.se/mediawiki/images/e/e3/${DRIVERS_TAR_GZ}
curl -LJO ${DRIVERS_URL} 2>/dev/null
exit_on_error $? "Failed downloading drivers ${DRIVERS_URL}"
echo " OK"

printf "%-${STR_SIZE}s"  "Unpack drivers: "
tar zxf Gu-print.tar.gz
exit_on_error $? "Failed unpacking drivers ${DRIVERS_TAR_GZ}"
echo " OK"

if [ "${ACCOUNT_NAME}" = "" ]
then
    #
    # interactive part
    #
    echo -n "Enter your \"x-account\" (e g xslave): "
    read ACCOUNT_NAME
fi

printf "%-${STR_SIZE}s"  "Stoping cups: "
cups_stop 2>/dev/null >/dev/null
exit_on_error $? "Failed stoping cups"
echo " OK"

printf "%-${STR_SIZE}s"  "Renaming printer conf: "
mv printers.conf printers.conf.orig
exit_on_error $? "Failed unpacking drivers ${DRIVERS_TAR_GZ}"
echo " OK"

printf "%-${STR_SIZE}s"  "Replacing account name: "
cat printers.conf.orig | sed "s,account,${ACCOUNT_NAME},g" > printers.conf
exit_on_error $? "Failed replacing account name"
echo " OK"

if [ $(sudo grep 'GUPrint' /etc/cups/printers.conf | wc -l) -eq 0 ] ;
then
    printf "%-${STR_SIZE}s"  "Adding GUPrint printers.conf: "
    sudo sh -c "cat printers.conf >> /etc/cups/printers.conf"
    exit_on_error $? "Failed adding GUPrint to printers.conf"
    echo " OK"
else
    printf "%-${STR_SIZE}s\n"  "GUPrint already defined in printers.conf, not adding"
fi

printf "%-${STR_SIZE}s"  "Copying GUPrint.ppd: "
sudo cp GUprint.ppd /etc/cups/ppd/
exit_on_error $? "Failed copying GUprint.ppd"
echo " OK"

if [ "$OS" = "macos" ]
then
    printf "%-${STR_SIZE}s"  "Copying toshiba specific stuff: "
    sudo mv Library/Printers/toshiba/ /Library/Printers/
    exit_on_error $? "Failed copying toshiba stuff"
    echo " OK"
    
    printf "%-${STR_SIZE}s"  "Changing permissions on toshiba stuff: "
    sudo chown -R root:admin /Library/Printers/toshiba/
    exit_on_error $? "Failed changing permissions on toshiba stuff"
    echo " OK"
    
fi

printf "%-${STR_SIZE}s"  "Starting cups: "
cups_start 2>/dev/null >/dev/null
exit_on_error $? "Failed starting cups"
echo " OK"


echo ""
echo "We've set up a printer"
echo " * name:    GUPrint"
echo " * account: ${ACCOUNT_NAME}"
