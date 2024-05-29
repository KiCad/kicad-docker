#!/bin/bash

REAL_RUN=false

while getopts 'i:a:p' opt
do
    case "${opt}" in
        i) IMAGE_BASE_NAME=${OPTARG};;
        a) ARCHES+=("$OPTARG");;
        p) REAL_RUN=true;;

        :) usage 1 "-$OPTARG requires an argument" ;;
        ?) usage 1 "Unknown option '$opt'" ;;
    esac
done

shift $((OPTIND -1))

if [[ -z "$IMAGE_BASE_NAME" ]]; then
    echo "-i arg required."
    exit;
fi

MANIFEST_SOURCES=""
MANIFEST_IMAGE=""
for arch in "${ARCHES[@]}"; do
    while read -r MANIFESTTAG && read -r ARCHTAG && read -r GLIMAGE
    do
        echo "Read tag: $ARCHTAG image: $GLIMAGE Arch:$arch"

        NEW_IMAGE="$IMAGE_BASE_NAME:$ARCHTAG"
        if [[ -z "$MANIFEST_IMAGE" ]]; then
            MANIFEST_IMAGE="$IMAGE_BASE_NAME:$MANIFESTTAG"
        fi

        echo "Creating tagged image: $NEW_IMAGE"
        if [ "$REAL_RUN" = true ] ; then
            docker pull $GLIMAGE
            docker tag $GLIMAGE $NEW_IMAGE
            #docker push $NEW_IMAGE
        else
            echo "Pulling: $GLIMAGE"
            echo "Tagging: $GLIMAGE to: $NEW_IMAGE"
            #echo "Pushing: $NEW_IMAGE"
        fi

        MANIFEST_SOURCES+="$NEW_IMAGE "
    done < "$arch-docker_tags.txt"

    if [ "$REAL_RUN" = true ] ; then
        docker buildx imagetools create -t ${MANIFEST_IMAGE} ${MANIFEST_SOURCES}
    else
        echo "Creating manifest: ${MANIFEST_IMAGE} from ${MANIFEST_SOURCES}"
    fi
done