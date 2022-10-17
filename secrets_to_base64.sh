#!/bin/bash

# this script is an instruction how to include the keystore file into github secrets

# steps:
# prepare keystore and key.properties files as per https://docs.flutter.dev/deployment/android#signing-the-app instruction
# note: keep them safe as stated in the instractions on the dart page.
# add directory /secrets-base64 to .gitignore 
# run following script optionally adjust keystore/key.peoperties file name
# add content of the generated files (base64 string) as github secrets value
# optionally: drop all generated files,
# Keep these files private; don’t check them into public source control.


echo "creating dir: ./secrets-base64"
mkdir secrets-base64
echo "encodeing..."
base64 android/app/qrkeeper-keystore.jks > secrets-base64/qrkeeper-keystore.jks.base64
echo "encoded keystore"
base64 android/key.properties > secrets-base64/key.properties.base64
echo "encoded key.properties"
echo "encoding done, do NOT commit this base64 files into your repository"
echo "use values from these files to create github secrets then remove them"