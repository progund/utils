#!/bin/bash

USER=$1

if [ "$USER" = "" ]
then
    echo "User name missing"
    exit 1
fi

GROUPSTOADD="adm cdrom sudo dip plugdev lpadmin sembashare dialout"
SUDO=echo

$SUDO adduser   "$USER" 
$SUDO addgroup "$USER"
$SUDO usermod a -G "$USER" "$USER"
for g in $GROUPSTOADD
do
    $SUDO usermod a -G "$USER" "$g"    
done
