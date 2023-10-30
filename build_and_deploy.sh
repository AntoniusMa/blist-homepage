#!/bin/sh

# Default value for target_directory
target_directory="./public"

# Parse command line flags
while [ $# -gt 0 ]; do
    case "$1" in
        --target-directory | -t)
            shift
            target_directory="$1"
            ;;
        --help | -h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --target-directory, -t  Specify the target directory"
            echo "  --help, -h              Display this help message"
            exit 0
            ;;
        *)
            # Unknown flag
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Prompt the user for confirmation
printf "This will delete the content of '$target_directory'. \n do you want to proceed? (y/n): "
read response

case "$response" in
    [yY])
        echo "Proceeding..."
        ;;
    [nN])
        echo "Build aborted."
        exit 0
        ;;
    *)
        echo "Invalid input. Aborting."
        exit 1
        ;;
esac

if sudo docker build -t hugo-release -f Containerfile .; then
    # create target directory if not exist
    mkdir -p $target_directory
    # clear target directory
    rm -r $target_directory/*
    # copy build to target directory
    sudo docker run --rm hugo-release tar -cf - public | tar -xvf - -C $target_directory --strip-components=1
else
    echo "Docker build failed, aborting..."
    exit 1
fi