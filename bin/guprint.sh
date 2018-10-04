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

if [ "$(uname  | grep -ic linux)" = "0" ]
then
    echo "This script only supports GNU/Linux"
    exit 1
fi

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

echo "Requiring sudo permissions"
sudo ls >/dev/null 2>/dev/null
exit_on_error $? "Failed getting sudo permissions"

TMP_DIR=/tmp/guprint-$$

STR_SIZE=20
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
    echo -n "Enter your \"x-account\" (e g xslawe): "
    read ACCOUNT_NAME
fi

printf "%-${STR_SIZE}s"  "Renaming printer conf: "
mv printers.conf printers.conf.orig
exit_on_error $? "Failed unpacking drivers ${DRIVERS_TAR_GZ}"
echo " OK"

printf "%-${STR_SIZE}s"  "Replacing account name: "
cat printers.conf.orig | sed "s,account,${ACCOUNT_NAME},g" > printers.conf

printf "%-${STR_SIZE}s"  "Copying printers.conf: "
sudo cp printers.conf /etc/cups/
exit_on_error $? "Failed copying printers.conf"
echo " OK"

printf "%-${STR_SIZE}s"  "Copying GUPrint.ppd: "
sudo cp GUprint.ppd /etc/cups/ppd/
exit_on_error $? "Failed copying GUprint.ppd"
echo " OK"

printf "%-${STR_SIZE}s\n"  "Restarting cups: "
if [ "$DIST" = "fedora" ]
then
    sudo service cups restart
else
    # non fedora => ubuntu or debian (otherwise an earlier error)
    sudo /etc/init.d/cups restart
fi
echo ""
echo "We've set up a printer"
echo " * name:    GUPrint"
echo " * account: ${ACCOUNT_NAME}"
