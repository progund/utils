#!/bin/bash


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


check_hello 0 Cleveland
check_hello 1 Einar Einar

check_Hello 0 Cleveland
check_Hello 1 Einar Einar

