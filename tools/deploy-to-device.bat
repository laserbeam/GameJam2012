call ../tools/settings.bat
7z u -r -tzip %BUNDLE_NAME% ./* -x!sample.moai
adb push %BUNDLE_NAME% /data/local/tmp/sample.moai
../tools/launch-on-device.bat