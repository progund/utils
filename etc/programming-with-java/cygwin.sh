#!/bin/bash

# This is not a crucial package for the Java course material, so discard errors

echo " *****************************************"
echo " * Installing groovy via separate script *"
echo " *****************************************"
curl -s get.sdkman.io | bash
RET=$?
if [ $RET -ne 0 ]
then
    echo "Failed downloading and executing sdk manager"
    return 0
fi

INIT_SH="$HOME/.sdkman/bin/sdkman-init.sh"
source "$INIT_SH"
RET=$?
if [ $RET -ne 0 ]
then
    echo "Failed sourcing $INIT_SH"
    return 0
fi

sdk install groovy
RET=$?
if [ $RET -ne 0 ]
then
    echo "Failed installing groovy"
    return 0
fi

echo "Finished installing groovy"
return 0

