#!/bin/sh

echo "Stage: PRE-Xcode Build is activated .... "

# Write a Swift File containing all the environment variables and secrets.
printf "let bgmAppID = \"%s\"\nlet bgmAppSecret = \"%s\" " "$bgmAppID" "$bgmAppSecret" >> ../moe.TV/DONOTUPLOAD.swift

echo "Wrote swift file."

echo "Stage: PRE-Xcode Build is DONE .... "

exit 0
