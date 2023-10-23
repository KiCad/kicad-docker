#!/bin/bash

while getopts 'i:' opt
do
    case "${opt}" in
        i) IMAGE_BASE_NAME=${OPTARG};;
        
        :) usage 1 "-$OPTARG requires an argument" ;;
        ?) usage 1 "Unknown option '$opt'" ;;
    esac
done

shift $((OPTIND -1))

if [[ -z "$IMAGE_BASE_NAME" ]]; then
    echo "-i arg required."
    exit;
fi

while read -r TAG && read -r GLIMAGE
do
    echo "Read tag: $TAG image: $GLIMAGE"

    NEW_IMAGE="$IMAGE_BASE_NAME:$TAG"

    echo "Creating tagged image: $NEW_IMAGE"
    docker pull $GLIMAGE
    docker tag $GLIMAGE $NEW_IMAGE
    docker push $NEW_IMAGE
done < "docker_tags.txt"