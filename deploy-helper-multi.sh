#!/bin/bash

REAL_RUN=false
declare -A MANIFESTS_MAP # Declare an associative array to map manifest images to their sources

usage() {
    exit_code=${1:-0} # Default exit code 0 if not provided
    message=$2
    if [[ -n "$message" ]]; then
        echo "Error: $message" >&2
    fi
    echo "Usage: $0 -i <image_base_name> [-t <tag_file>]... [-p]" >&2
    echo "  -i : Base name for the target Docker images (e.g., myrepo/myimage)."
    echo "  -t : Path to a tag file. Can be specified multiple times."
    echo "       Each tag file should contain lines in triplets:"
    echo "         <manifest_tag> (e.g., latest, v1.0)"
    echo "         <sub-tag> (e.g., 9.0-arm64, 9.0-amd64)"
    echo "         <source_image> (e.g., registry.gitlab.com/user/project/image:sub-tag)"
    echo "       Tag files can use Unix (LF) or Windows (CRLF) line endings."
    echo "  -p : Perform real run (pull, tag, push, manifest). Default is dry-run."
    exit "$exit_code"
}

while getopts 'i:t:p' opt
do
    case "${opt}" in
        i) IMAGE_BASE_NAME=${OPTARG};;
        t) TAG_FILES+=("$OPTARG");;
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

if [[ ${#TAG_FILES[@]} -eq 0 ]]; then
    usage 1 "-t <tag_file> argument must be provided at least once."
fi


echo "--- Processing Tag Files ---"
for tag_file in "${TAG_FILES[@]}"; do
    echo "Reading tag file: $tag_file"
    if [[ ! -f "$tag_file" ]]; then
        echo "Error: Tag file '$tag_file' not found."
        exit 1
    fi

    while read -r MANIFESTTAG && read -r ARCHTAG && read -r GLIMAGE
    do
        # Strip potential trailing carriage return characters (\r) from CRLF files
        MANIFESTTAG=${MANIFESTTAG%$'\r'}
        ARCHTAG=${ARCHTAG%$'\r'}
        GLIMAGE=${GLIMAGE%$'\r'}

        echo "Read manifest tag: $MANIFESTTAG, arch tag: $ARCHTAG, source image: $GLIMAGE"

        NEW_IMAGE="$IMAGE_BASE_NAME:$ARCHTAG"
        TARGET_MANIFEST_IMAGE="$IMAGE_BASE_NAME:$MANIFESTTAG"

        echo "Creating tagged image: $NEW_IMAGE"
        if [ "$REAL_RUN" = true ] ; then
            echo "Pulling: $GLIMAGE"
            docker pull $GLIMAGE

            echo "Tagging: $GLIMAGE -> $NEW_IMAGE"
            docker tag $GLIMAGE $NEW_IMAGE

            echo "Pushing: $NEW_IMAGE"
            docker push $NEW_IMAGE
        else
            echo "Pulling: $GLIMAGE"
            echo "Tagging: $GLIMAGE to: $NEW_IMAGE"
            echo "Pushing: $NEW_IMAGE"

            # Add to map even in dry run to show what manifest would be created
            MANIFESTS_MAP["$TARGET_MANIFEST_IMAGE"]+="$NEW_IMAGE "
        fi

        MANIFEST_SOURCES+="$NEW_IMAGE "
    done < "$tag_file"
done



echo
echo "--- Creating Manifests ---"
if [[ ${#MANIFESTS_MAP[@]} -eq 0 ]]; then
    echo "No images were successfully processed or added for manifest creation."
    exit 0 # Exit cleanly if nothing to manifest
fi

for manifest_image in "${!MANIFESTS_MAP[@]}"; do
    # Get the space-separated list of source images for this manifest
    local_sources=${MANIFESTS_MAP[$manifest_image]}
    # Remove trailing space (optional but good practice)
    local_sources=$(echo "$local_sources" | sed 's/ *$//')

    if [[ -z "$local_sources" ]]; then
        echo "Warning: No source images found for manifest '$manifest_image'. Skipping."
        continue
    fi

    echo "Creating manifest: ${manifest_image} from sources:"
    echo "$local_sources"
    if [ "$REAL_RUN" = true ] ; then
        # Use word splitting intentionally here by not quoting $local_sources
        if ! docker buildx imagetools create -t "${manifest_image}" $local_sources; then
            echo "Error: Failed to create manifest ${manifest_image}"
        else
            echo "Successfully created manifest ${manifest_image}"
        fi
    else
      echo "Dry run: Would run: docker buildx imagetools create -t \"${manifest_image}\" ${local_sources}"
    fi
    echo # Add a newline for better readability

    echo
done

echo "--- Script Finished ---"
exit 0