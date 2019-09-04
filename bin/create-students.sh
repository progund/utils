#!/bin/bash

FILE=$1
LOG_FILE=/tmp/create-students-$$.log
HOME_DIR_BASE=/home
WWW_DIR=/var/www/html/tig015/2019/

log()
{
    echo "$*" >> $LOG_FILE
}

exec_cmd()
{
    echo "$*" | bash
    RET=$?
    if [ $RET -ne 0 ]
    then
        echo "Failed executing \"$*\" (return code: $RET)"
 #       exit $RET
    fi
}

create_group()
{
    NEW_GROUP=$1
    exec_cmd "groupadd $NEW_GROUP"
    NEW_GROUP=
}

create_user()
{
    NEW_GROUP=$1
    NEW_USER=$2
#    echo "  ** CREATE USER:  $NEW_USER ($NEW_GROUP)"
    WWW_USER_DIR=${HOME_DIR_BASE}/${NEW_USER}/public_html/

    exec_cmd "useradd -m -b ${HOME_DIR_BASE} $NEW_USER"
    if [ "$NEW_GROUP" != "" ]
    then
        sudo usermod -a -G $NEW_GROUP $NEW_USER
    fi
    exec_cmd "chpasswd $NEW_USER:${NEW_USER}$$"
#    exec_cmd "echo  | passwd $NEW_USER --stdin"
    exec_cmd "mkdir ${WWW_USER_DIR}"
    exec_cmd "chown -R ${NEW_USER}. ${WWW_USER_DIR}"
    GROUP_ARGS=""
    NEW_USER=
    NEW_GROUP=
    echo -e "Test page\nCreated: $(LC_TIME=en_GB.UTF-8 date)" > $WWW_USER_DIR/test.txt
    if [ "$NEW_GROUP" != "" ]
    then
	echo "Adding student to group file $WWW_DIR/$NEW_GROUP/test.txt" 
	echo " * $NEW_USER" >> $WWW_DIR/$NEW_GROUP/test.txt
    fi    
}

cat $FILE | while read LINE
do
#    echo "$LINE"
    USERS=$LINE
    USE_GROUP=$(echo $LINE | grep -c ":" )
    if [ $USE_GROUP -ne 0 ]
    then
        GROUP=$(echo $LINE | cut -d':' -f 1)
        USERS=$(echo $LINE | cut -d':' -f 2)
        create_group $GROUP
	mkdir -p $WWW_DIR/$GROUP
	echo -e "Test page for group: $GROUP\nCreated: $(LC_TIME=en_GB.UTF-8 date)\nStudents:" > $WWW_DIR/$GROUP/test.txt
	chown -R www-data.$GROUP $WWW_DIR/$GROUP
	
    fi

    for i in $(echo $USERS | sed 's/,/ /g')
    do
        create_user "$GROUP" "$i"
        echo "$GROUP" "$i"
    done
    GROUP=
done 
