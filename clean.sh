#!/bin/bash

# Arguments
prefix=""
suffix=""
directory=""
delete=""
deleteAll=""

# Parse command line arguments
while getopts "p:s:d:-:" opt; do
    case $opt in
        p | prefix)
            prefix="$OPTARG"
            ;;
        s | suffix)
            suffix="$OPTARG"
            ;;
        d | directory)
            directory="$OPTARG"
            ;;
        - | delete)
            delete="true"
            ;;
        - | delete-all)
            deleteAll="true"
            ;;
        *)
            echo "Unknown option: $OPTARG"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))
# Handle different flags
case $delete in
    "true")
        # Delete files
        find "$directory" -type f -name "*$prefix*$suffix" -exec rm -f {} \;
        ;;
    *)
        # Archive files
        archiveDir="archive"
        # Check if archive directory exists, if not create it
        if [ ! -d "$archiveDir" ]; then
            mkdir "$archiveDir"
        fi
        # Move files to archive directory
        find "$directory" -type f -name "*$prefix*$suffix" -exec mv {} "$archiveDir" \;
        # Archive files into .tar.gz
        tar -czvf "$archiveDir.tar.gz" "$archiveDir"
        ;;
esac

# Handle --delete-all flag
case $deleteAll in
    "true")
        # Delete all files with the same prefix
        find "$directory" -type f -name "$prefix*" -exec rm -f {} \;
        ;;
esac
# Uncomment the line below if you want to delete the files instead of archiving
# find . -type f -name "*$simName*$suffix" -exec rm -f {} \;