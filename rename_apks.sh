#!/bin/bash

# rename apks for pushing them to releases

tag=$1
if test -z $tag 
then
	echo 'missing "tag" value'
	exit 1
fi

apks_path="./build/app/outputs/flutter-apk"

for f in $apks_path/*.apk; do echo "-- $f"; done

echo "the tag is: $tag"

for f in $apks_path/*.apk; do
	mv "$f" "${f/"app-"/"qrkeeper-$tag-"}"
done

for f in $apks_path/*.apk; do echo "-- $f"; done
