#!/usr/bin/env bash

if ! [ -x "$(command -v marathon)" ]; then
    echo "Please install Marathon using the Swift Package Manager to take advantage of automatic code generation and other Swift Scripting fun."
    echo "Instructions: https://github.com/JohnSundell/Marathon#on-macos"
    exit 0
fi


if [ -z "$SRCROOT" ]; then
  # If the source root isn't set, go a directory up from the current working directory
  # (NOTE: Assumes you're calling this script from the `Scripts` directory)
  WORKING_DIR=$(pwd)
  SRCROOT=$(dirname $WORKING_DIR)
  export SRCROOT
fi

marathon run "${SRCROOT}/Toshi/Generated/Scripts/StencilScript.swift"
