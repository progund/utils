#!/bin/bash


THIS_SCRIPT_DIR=$(dirname $0)/../bin
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

check_presence()
{
    PROG=$1
    echo -n "Checking program $PROG: "
    which $PROG 2>/dev/null >/dev/null 
    exit_on_error "$?" "Could not find program: $PROG"
    echo " OK"
}

check_hello()
{
    EXP_RET=$1
    EXP_PRINT=$2
    ARGS=$3
    ./hello $ARGS
    RET=$?
    PRINT_CHECK=$(./hello $ARGS | grep $EXP_PRINT|wc -l)

    if [ "$PRINT_CHECK" != "0" ] && [ $RET -eq $EXP_RET ]
    then
        return 0
    else
        echo "Test of hello failed:"
        echo " * return value was $RET expected $EXP_RET"
        echo " * expected to see 1 or more $EXP_PRINT"
        exit 1
    fi
}


check_Hello()
{
    EXP_RET=$1
    EXP_PRINT=$2
    ARGS=$3
    java Hello $ARGS
    RET=$?
    PRINT_CHECK=$(java Hello $ARGS | grep $EXP_PRINT|wc -l)

    if [ "$PRINT_CHECK" != "0" ] && [ $RET -eq $EXP_RET ]
    then
        return 0
    else
        echo "Test of hello failed:"
        echo " * return value was $RET expected $EXP_RET"
        echo " * expected to see 1 or more $EXP_PRINT"
        exit 1
    fi
}


echo Checking gcc
echo -n "*"
check_hello 0 Cleveland
echo -n "*"
check_hello 1 Einar Einar

echo Checking javac
echo -n "*"
check_Hello 0 Cleveland
echo -n "*"
check_Hello 1 Einar Einar


if [ "$OS" = "Linux" ]
then
    check_presence valgrind
    check_presence arduino
    check_presence gcov
    check_presence wget
    check_presence curl
fi



