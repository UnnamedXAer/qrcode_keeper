#install
# Connect your Android device to your computer with a USB cable.
# Enter cd [project].
# Run flutter install.


# example:
#  "🔢 Update version number"; code pubspec.yaml;
# ./build -flavor production

param ($buildType = 'release', $flavor = 'staging', [switch]$buildAssets = $false, [switch]$install = $false)

$mainFileDir;

switch ($flavor) {
	"development" {
		$mainFileDir = "main_dev.dart"
	}
	"staging" {
		$mainFileDir = "main_stag.dart"
	}
	"production" {
		$mainFileDir = "main_prod.dart"
	}
}



Write-Host "Build type: $buildType"
Write-Host "Flavor: $flavor"
Write-Host "Target main file: $mainFileDir"


# if ($install) {
# 	Write-Host "Deleting previous apks from $buildApks..."
# 	if ($path.Exists) {
# 		Remove-Item "$buildApks"
# 	}
# 	else {
# 		Write-Host "Folder does not exists"
# 	}
# }

Write-Host "Getting packages..."
flutter pub get

if ($buildAssets) {
	Write-Host "Generating splash screen..."
	flutter pub run flutter_native_splash:create --flavor $flavor
	Write-Host "Generating launcher icons for $flavor..."
	flutter pub run flutter_launcher_icons:main -f "flutter_launcher_icons-$flavor.yaml"
}
else {
	Write-Host "Rebuilding assets skipped, pass -buildAssets to trigger rebuilding"
}
# flutter build appbundle "--release" --flavor staging -t "lib/main_stag.dart" 
flutter build apk --split-per-abi "--$buildType" --flavor $flavor -t "lib/$mainFileDir"

$buildApks = "build/app/outputs/apk/$flavor/$buildType/app-$flavor-armeabi-v7a-$buildType.apk"
Write-Host "Build Apks: $buildApks"
if ($install) {
	flutter install --use-application-binary=$buildApks
}
