#!/bin/bash


THIS_SCRIPT_DIR=$(dirname $0)
BASH_FUNCTIONS=${THIS_SCRIPT_DIR}/bash-functions
if [ -f ${BASH_FUNCTIONS} ]
then
    echo "Sourcing file:  ${BASH_FUNCTIONS}"
    . ${BASH_FUNCTIONS}
else
    echo -n "Failed finding file: ${BASH_FUNCTIONS}. "
    echo "Bailing out..."
    exit 1
fi

source_file ${THIS_SCRIPT_DIR}/settings

${THIS_SCRIPT_DIR}/jd-download-software.sh
exit_on_error "$?" "Failed downloading system software"

# For Arduino
if [ "$OS" = "linux" ] && [ "$CUR_USER" != "" ]
then
    $SUDO usermod -a -G dialout "$CUR_USER" 2>/dev/null
fi

#
# Bail out if not full install
#
while [ "$*" != "" ]
do
    case "$1" in
        "--full")
            FULL_MODE=true
            ;;
        "--verify")
            VERIFY_MODE=true
            ;;
        *)
            echo "SYNTAX ERROR: $1"
            ;;
    esac
    shift
done

if [ "$FULL_MODE" = "true" ]
then
    ${THIS_SCRIPT_DIR}/jd-verify-sw.sh
fi
    
if [ "$VERIFY_MODE" = "true" ]
then
    exit 0
fi
    
${THIS_SCRIPT_DIR}/jd-dload-techbooks.sh
exit_on_error "$?" "Failed downloading juneday educational repositories"

if [ "OS" = "linux" ]
then
       sudo usermod -a -G dialout $USER
fi

pushd ${THIS_SCRIPT_DIR}/../test
make check
exit_on_error "$?" "Failed verifying development softwares"
popd

${THIS_SCRIPT_DIR}/jd-install-desktop-entries.sh
exit_on_error "$?" "Failed creating desktop entries"

${THIS_SCRIPT_DIR}/jd-setup-user.sh
exit_on_error "$?" "Failed setting up stuff for user"
