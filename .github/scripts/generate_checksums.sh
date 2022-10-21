#!/bin/bash

# generate checksums for the apks

apks_path="./build/app/outputs/flutter-apk"
back=../../../../../

cd $apks_path

content=""
for f in ./qrkeeper-*.apk; do
	content="$content$(sha256sum $f)
"
done

cd $back

echo "$content"