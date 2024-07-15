#!/bin/sh

echo "Stage: PRE-Xcode Build is activated .... "

# Move to the place where the scripts are located.
# This is important because the position of the subsequently mentioned files depend of this origin.
cd $CI_WORKSPACE/ci_scripts || exit 1

# Write a Swift File containing all the environment variables and secrets.
printf "let bgmAppID = \"%s\"\nlet bgmAppSecret = \"%s\" " "$bgmAppID" "$bgmAppSecret" >> ../moe.TV/DONOTUPLOAD.swift

echo "Wrote swift file."

echo "Stage: PRE-Xcode Build is DONE .... "

exit 0
