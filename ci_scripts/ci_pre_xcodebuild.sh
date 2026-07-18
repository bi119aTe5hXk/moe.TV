#!/bin/sh

echo "Stage: PRE-Xcode Build is activated .... "

# Write a Swift File containing all the environment variables and secrets.
{
	printf "let bgmAppID = \"%s\"\n" "$bgmAppID"
	printf "let bgmAppSecret = \"%s\"\n" "$bgmAppSecret"
	printf "let testURL = \"%s\"\n" "$testURL"
	printf "let albireoV2ClientID = \"%s\"\n" "$albireoV2ClientID"
	printf "let albireoV2DefaultAPIServerURL = \"%s\"\n" "$albireoV2DefaultAPIServerURL"
} >> ../moe.TV/DONOTUPLOAD.swift

echo "Wrote swift file."

echo "Stage: PRE-Xcode Build is DONE .... "

exit 0
