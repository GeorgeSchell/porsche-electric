#!/bin/zsh
# Rebuilds the app, signs it for the registered iPhones and publishes it on https://georgeschell.github.io/my-cayenne/
# After adding a friend's UDID at developer.apple.com (Devices), just run: ./publish.sh
set -e
cd "${0:A:h}"
app=../MyCayenne
work=$(mktemp -d)

xcodebuild -project $app/MyCayenne.xcodeproj -scheme MyCayenne -configuration Release -destination 'generic/platform=iOS' \
  -archivePath $work/MyCayenne.xcarchive -derivedDataPath $work/dd -allowProvisioningUpdates DEVELOPMENT_TEAM=L9X6HR23RJ archive -quiet
xcodebuild -exportArchive -archivePath $work/MyCayenne.xcarchive -exportOptionsPlist ExportOptions.plist \
  -exportPath $work/export -allowProvisioningUpdates -quiet

cp $work/export/MyCayenne.ipa MyCayenne.ipa
sed 's#<string>MyCayenne</string>#<string>Porsche Electric</string>#' $work/export/manifest.plist > manifest.plist

# version and date on the install button
info=$work/MyCayenne.xcarchive/Products/Applications/MyCayenne.app/Info.plist
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' $info)
build=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' $info)
date=$(LC_ALL=en_GB.UTF-8 date '+%-d %b %Y')
sed -i '' -E "s#<span id=\"buildInfo\">[^<]*</span>#<span id=\"buildInfo\">Version $version ($build) · $date</span>#" index.html

(cd $work && unzip -oq export/MyCayenne.ipa)
devices=$(security cms -D -i $work/Payload/MyCayenne.app/embedded.mobileprovision | plutil -extract ProvisionedDevices raw -)
echo "Signed for $devices registered iPhones."

git add -A
git commit -m "Build $version ($build), $date" ${COMMIT_TRAILER:+-m "$COMMIT_TRAILER"} -q
git push -q
rm -rf $work
echo "Published. GitHub Pages updates in about a minute."
