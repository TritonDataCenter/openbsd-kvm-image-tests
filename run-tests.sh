#!/usr/bin/env bash

if [[ -n "$TRACE" ]]; then
    export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -o xtrace
fi
set -euo pipefail

IFS=$'\n\t'

DATE=$(date +%H%M%S)

usage() {
cat <<EOF

Setup test instances and run tests for given image.

Note: This script assumes you have the triton cli command tool setup with a
      profile for your test environment.

This script will:

    - Create a test instance of the given image with user-script, user-data,
      a public IP and private IP.
    - Create a custom image of the test instance.
    - Create a test instance from the custom image.
    - Run tests on the above instances.

    Usage:

        $0 -i <IMAGE> -p <PROFILE> -n <PROPER_NAME>

    Example:

        $0 -i 04ad406c-3d9e-11e7-89b4-d3f2a3e27819 -p testing-dc -n "OpenBSD 6.1"

    Options:

        -i The image you want to test. Can be UUID or image name.
        -p The profile you wish to use. This assumes you have the triton
           CLI tool setup with your desired profile.
        -n The name of the image. This is the proper name found in the
           motd and /etc/product files. Should be in quotes.
        -h Show this message

EOF
exit 1
}

IMAGE=
PROFILE=
PROPER_NAME=
PACKAGE=
IMAGENAME=
VERSION=
UUID=
TAG="test-instance=true"
UUID=
SCRIPT=$PWD/userscript.sh
METADATAFILE="user-data=$PWD/user-data"

while getopts “hi:p:n:” OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    i)
      IMAGE=$OPTARG
      ;;
    p)
      PROFILE=$OPTARG
      ;;
    n)
      PROPER_NAME=$OPTARG
      ;;
    ?)
      usage
      exit
      ;;
  esac
done

if [[ -z $IMAGE ]] || [[ -z $PROFILE ]] || [[ -z $PROPER_NAME ]]; then
    usage
    exit 1
fi


get_image_details() {
    echo ""
    echo "Getting image details:"
    IMAGEDETAILS=$(triton -p ${PROFILE} image get $1 | json -a name version id)
    IMAGENAME=$(echo $IMAGEDETAILS | cut -d ' ' -f 1)
    VERSION=$(echo $IMAGEDETAILS | cut -d ' ' -f 2)
    UUID=$(echo $IMAGEDETAILS | cut -d ' ' -f 3)
    echo "    $IMAGEDETAILS"
    echo ""
}

choose_package() {
    PACKAGE=k4-highcpu-kvm-3.75G
    echo "Using package:"
    echo "    $PACKAGE"
    echo ""
}

get_networks() {
    echo "Getting networks:"

    PUBLIC_NETWORK=$(triton -p ${PROFILE} network list -j | json -ag id -c 'this.public === true' | head -1)
    PRIVATE_NETWORK=$(triton -p ${PROFILE} network list -j | json -ag id -c 'this.public === false' -c 'this.fabric !== true' | head -1)

    # Trying using a fabric network instead
    if [[ -z "$PRIVATE_NETWORK" ]]; then
        PRIVATE_NETWORK=$(triton -p ${PROFILE} network list -j | json -ag id -c 'this.public === false' | head -1)
    fi

    echo "    Public:  $PUBLIC_NETWORK"
    echo "    Private: $PRIVATE_NETWORK"
    echo ""
}

cat <<USERSCRIPT >userscript.sh
echo "testing user-script" >> /var/tmp/test
hostname $IMAGENAME

USERSCRIPT

cat <<USERDATA >user-data
This is user-data!

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore
eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt
in culpa qui officia deserunt mollit anim id est laborum.
USERDATA

create_instance() {
    local IMAGE=$1
    local INST_NAME=$2
    echo "Provisioning:"
    triton -p ${PROFILE} instance create -w -n $INST_NAME -N $PUBLIC_NETWORK -N $PRIVATE_NETWORK -t $TAG --script=$SCRIPT -M $METADATAFILE $IMAGE $PACKAGE
}

wait_for_IP() {
    local INST_NAME=$1
    echo "Checking Public IP:"

    while [[ true ]]; do
        echo -n "."
        ping -c1 $(triton -p ${PROFILE} instance ip $INST_NAME) > /dev/null && break;
    done
    echo ""
    echo "IP is now live."
}

wait_for_ssh() {
    local INST_NAME=$1
    local COUNT=0
    echo "Checking ssh on $INST_NAME"
    # Time out after a minute
    while [[ "$COUNT" -lt 60 ]]; do
        echo -n "."
        ssh -q root@$(triton -p ${PROFILE} instance ip $INST_NAME) exit > /dev/null && break;
        sleep 1
        COUNT=$((COUNT+1))
    done

    if [[ "$COUNT" -ge 60 ]]; then
      echo "ssh timed out after ~60 seconds"
      exit 1
    fi
}

test_image() {
    local INST_NAME=$1

cat <<PROPYML >properties.yml
$INST_NAME:
  :roles:
    - openbsd
  :name: $PROPER_NAME
  :version: $VERSION
  :doc_url: https://docs.joyent.com/images/kvm/openbsd
PROPYML

    export TARGET_HOST_NAME=$(triton -p ${PROFILE} instance ip $INST_NAME)
    export TARGET_USER_NAME=root
    rake serverspec

    echo "###########################"
    echo "All OpenBSD tests PASSED."
    echo "###########################"
    echo ""
}

create_custom_image() {
    local INSTANCE=$1
    local CUSTOM_IMAGE=$IMAGENAME-CUST
    # This is here to workaround a bug where the instance is not stopped properly
    echo "Stopping $INSTANCE"
    triton -p ${PROFILE} instance stop -w $INSTANCE
    echo "Creating custom image of $INSTANCE"
    triton -p ${PROFILE} image create -w -t $TAG $INSTANCE $CUSTOM_IMAGE $VERSION
    echo "Restarting $INSTANCE"
    triton -p ${PROFILE} instance start -w $INSTANCE
}

delete_instance() {
    local INST_NAME=$1
    echo "Deleting test instance $INST_NAME"
    triton -p ${PROFILE} instance delete $INST_NAME
}

delete_image() {
    local CUSTOM_IMAGE=$1
    triton -p ${PROFILE} image delete -f $CUSTOM_IMAGE
}

cleanup() {
    echo "Cleaning up."

    rm -rf userscript.sh
    rm -rf user-data

    unset TARGET_HOST_NAME
    unset TARGET_USER_NAME
    echo "Done."
    echo ""
}

get_image_details $IMAGE
choose_package
get_networks

INSTANCE_NAME=${IMAGENAME}-${VERSION}-${DATE}

create_instance $IMAGE $INSTANCE_NAME
wait_for_IP $INSTANCE_NAME
wait_for_ssh $INSTANCE_NAME

echo "Sleeping for 60 seconds"
sleep 60

test_image $INSTANCE_NAME

#create_custom_image $INSTANCE_NAME
#
#get_image_details $IMAGENAME-CUST
#choose_package
#get_networks
#
#CUSTOM_INSTANCE_NAME=${IMAGENAME}-${VERSION}-${DATE}
#
#create_instance $IMAGENAME $CUSTOM_INSTANCE_NAME
#wait_for_IP $CUSTOM_INSTANCE_NAME
#wait_for_ssh $CUSTOM_INSTANCE_NAME
#
#test_image $CUSTOM_INSTANCE_NAME

echo "Deleting instance and custom image"
ssh-keygen -q -R $(triton inst ip $INSTANCE_NAME)
delete_instance $INSTANCE_NAME
#ssh-keygen -q -R $(triton inst ip $CUSTOM_INSTANCE_NAME)
#delete_instance $CUSTOM_INSTANCE_NAME
#delete_image $IMAGENAME
cleanup

exit 0
