#!/bin/bash -e

cd "$(dirname "$0")"

IMAGE_TAG=$1

# run common tests
../test.sh --full-image-name ubi-ruby-fips:"$IMAGE_TAG" --test-file-name test-ubi.yml