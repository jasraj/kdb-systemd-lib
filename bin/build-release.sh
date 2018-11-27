#!/usr/bin/env bash

## kdb Integration with systemd - Package Builder
## Copyright (c) 2018 Jaskirat Rajasansir

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))

readonly GIT_TAG=$1

readonly GIT_REPO_URL=https://github.com/jasraj/kdb-systemd-lib.git
readonly CHECKOUT_DIR=$(mktemp -d)
readonly BUILD_DIR=$(mktemp -d)
readonly BUILD_TEMP_OUT=$(mktemp)

main()
{
    if [[ $GIT_TAG == "" ]]; then
        usage
        exit 1
    fi

    local checkMake=$(which make > /dev/null; echo $?)

    if [[ $checkMake -ne 0 ]]; then
        echo "ERROR: 'make' not found in path. Cannot build"
        exit 1
    fi

    pushd $CHECKOUT_DIR > /dev/null

    echo "Cloning GIT repository for specific tag [ Repo: $GIT_REPO_URL ] [ Tag: $GIT_TAG ] [ Target: $CHECKOUT_DIR ]"

    git clone $GIT_REPO_URL --recursive $CHECKOUT_DIR
    git checkout $GIT_TAG

    if [[ $? -ne 0 ]]; then
        echo -e "\nERROR: Failed to clone repository / checkout tag [ Repo: $GIT_REPO_URL ] [ Tag: $GIT_TAG ]"
        exit 2
    fi

    local makeFile=$CHECKOUT_DIR/Makefile

    if [[ ! -e $makeFile ]]; then
        echo -e "\nERROR: Failed to find expected Makefile in build root [ [ Repo: $GIT_REPO_URL ] [ Tag: $GIT_TAG ]"
        exit 3
    fi

    echo -e "\nCompiling shared library and packaging [ Output File: $BUILD_TEMP_OUT ]"

    export KSL_OUT=$BUILD_DIR

    make clean
    make all

    if [[ $? -ne 0 ]]; then
        echo -e "\nERROR: Build failed. Check output above and try again"
        exit 4
    fi

    local tarBuildDir=${BUILD_DIR/\//}

    tar --exclude-vcs --transform "s|$tarBuildDir|$(git describe)|" -cvzf $BUILD_TEMP_OUT $BUILD_DIR

    if [[ $? -ne 0 ]]; then
        echo -e "\nERROR: Failed to generate build package [ File: $BUILD_TEMP_OUT ]"
        exit 5
    fi

    echo -e "\nDeployment package built. Copying to current working directory [ File: $BUILD_TEMP_OUT ]"

    popd > /dev/null
    mv $BUILD_TEMP_OUT $(pwd)/${GIT_TAG}.tar.gz

    echo -e "\nBUILD COMPLETE"
}

usage()
{
    cat <<UsageOut
$0 *tag-to-build*

    *tag-to-build*: The git tag in the repository to create a TAR GZ for

UsageOut
}

cleanup()
{
    rm -rf $CHECKOUT_DIR $BUILD_DIR
    rm -f $BUILD_TEMP_OUT

    echo ""
}

trap cleanup INT EXIT


main
