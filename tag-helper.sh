#!/bin/bash

unset -v BUILD_TYPE
unset -v TAG_BASE_NAME

PUSH_IMAGE=false

while getopts 'o:a:c:t:b:r:i:p' opt
do
    case "${opt}" in
        c) ORIG_CONTAINER=${OPTARG};;
        t) BUILD_TYPE=${OPTARG};;
        b) TAG_BASE_NAME=${OPTARG};;
        r) RELEASE_TAG=${OPTARG};;
        i) IMAGE_BASE_NAME=${OPTARG};;
        p) PUSH_IMAGE=true;;
        a) ARCH=${OPTARG};;
        o) TAGS_FILENAME=${OPTARG};;

        :) usage 1 "-$OPTARG requires an argument" ;;
        ?) usage 1 "Unknown option '$opt'" ;;
    esac
done

shift $((OPTIND -1))

if [[ -z "$ORIG_CONTAINER" ]]; then
    echo "-c arg required."
    exit;
fi

if [[ -z "$BUILD_TYPE" ]]; then
    echo "-t arg required."
    exit;
fi

if [[ -z "$IMAGE_BASE_NAME" ]]; then
    echo "-i arg required."
    exit;
fi

if [[ -z "$TAGS_FILENAME" ]]; then
    TAGS_FILENAME="docker_tags.txt"
fi

#
# BUILD_TYPE
# 'monthly' - will append the current YYYYMM to the container base name
# 'daily' - will simply return back the current base name
# 'release' - will r
#
# BUILD_TAG - required for release
#

> "${TAGS_FILENAME}"
# Check if the KI_BUILD_TYPE variable is "monthly"
if [[ "$BUILD_TYPE" == "monthly" ]]; then
    if [[ -z "$TAG_BASE_NAME" ]]; then
        echo "-b arg required."
        exit;
    fi

    # Generate a string containing the current month and year in format YYYYMM
    MONTH_YEAR_STRING=$(date +"%Y%m")

    # Print the month and year string
    CONTAINER_TAG="${TAG_BASE_NAME}-${MONTH_YEAR_STRING}"
    CONTAINER_IMAGE="$IMAGE_BASE_NAME:$CONTAINER_TAG"

    echo $CONTAINER_TAG >> "${TAGS_FILENAME}"
    echo $CONTAINER_IMAGE >> "${TAGS_FILENAME}"

    if [ "$PUSH_IMAGE" = true ] ; then
        docker tag $ORIG_CONTAINER $CONTAINER_IMAGE
        docker push $CONTAINER_IMAGE
    fi
elif [[ "$BUILD_TYPE" == release* ]]; then
    if [[ $RELEASE_TAG =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]];
    then
        FULL_VERSION=${BASH_REMATCH[0]}
        MAJOR_MINOR_VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    else
        echo "-r is required for release builds and must be a properly formatted version MAJOR.MINOR.PATCH."
        exit;
    fi

    # Major minor tag
    CONTAINER_TAG="${MAJOR_MINOR_VERSION}"
    CONTAINER_TAG_ORIG=$CONTAINER_TAG
    if [ "$ARCH" ]; then
        CONTAINER_TAG="${CONTAINER_TAG}-${ARCH}"
    fi

    CONTAINER_IMAGE="$IMAGE_BASE_NAME:$CONTAINER_TAG"

    # now dump to file
    if [ "$ARCH" ]; then
        echo $CONTAINER_TAG_ORIG >> "${TAGS_FILENAME}"
    fi
    echo $CONTAINER_TAG >> "${TAGS_FILENAME}"
    echo $CONTAINER_IMAGE >> "${TAGS_FILENAME}"

    if [ "$PUSH_IMAGE" = true ] ; then
        docker tag $ORIG_CONTAINER $CONTAINER_IMAGE
        docker push $CONTAINER_IMAGE
    fi

    # Full version tag

    CONTAINER_TAG="${FULL_VERSION}"
    CONTAINER_TAG_ORIG=$CONTAINER_TAG
    if [ "$ARCH" ]; then
        CONTAINER_TAG="${CONTAINER_TAG}-${ARCH}"
    fi

    CONTAINER_IMAGE="$IMAGE_BASE_NAME:$CONTAINER_TAG"

    # now dump to file
    if [ "$ARCH" ]; then
        echo $CONTAINER_TAG_ORIG >> "${TAGS_FILENAME}"
    fi
    echo $CONTAINER_TAG >> "${TAGS_FILENAME}"
    echo $CONTAINER_IMAGE >> "${TAGS_FILENAME}"

    if [ "$PUSH_IMAGE" = true ] ; then
        docker tag $ORIG_CONTAINER $CONTAINER_IMAGE
        docker push $CONTAINER_IMAGE
    fi
elif [[ "$BUILD_TYPE" == "daily" ]]; then
    if [[ -z "$TAG_BASE_NAME" ]]; then
        echo "-b arg required."
        exit;
    fi

    CONTAINER_TAG="${TAG_BASE_NAME}"
    CONTAINER_TAG_ORIG=$CONTAINER_TAG
    if [ "$ARCH" ]; then
        CONTAINER_TAG="${CONTAINER_TAG}-${ARCH}"
    fi

    CONTAINER_IMAGE="$IMAGE_BASE_NAME:$CONTAINER_TAG"

    if [ "$ARCH" ]; then
        echo $CONTAINER_TAG_ORIG >> "${TAGS_FILENAME}"
    fi
    echo $CONTAINER_TAG >> "${TAGS_FILENAME}"
    echo $CONTAINER_IMAGE >> "${TAGS_FILENAME}"

    if [ "$PUSH_IMAGE" = true ] ; then
        docker tag $ORIG_CONTAINER $CONTAINER_IMAGE
        docker push $CONTAINER_IMAGE
    fi
fi

if [ "$PUSH_IMAGE" = true ] ; then
    echo "Tagged and pushed images"
else
    echo "Dry-run, saved ${TAGS_FILENAME}"
fi