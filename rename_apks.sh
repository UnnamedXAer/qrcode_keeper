#!/bin/bash

# rename apks for pushing them to releases

run_num=$1
if test -z $run_num 
then
	echo 'missing "run_num" value'
	exit 1
fi

apks_path="./build/app/outputs/flutter-apk"

for f in $apks_path/*.apk; do echo "-- $f"; done

echo "the run_num is: $run_num"

for f in $apks_path/*.apk; do
	mv "$f" "${f/"app-"/"qrkeeper-$run_num-"}"
done

for f in $apks_path/*.apk; do echo "-- $f"; done
