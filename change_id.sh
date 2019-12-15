#!/bin/bash

# Below the strings that have to be adjusted.
# WARNING: This script will change itself.

app_id_old=com.occase.carway
old_label='label="Carway"'
app_id_new=com.occase.car

new_app_name=$(grep appName data/parameters.txt | awk -F: '{print $2}' | tr -d '"' | tr -d ' ')
new_label="label=\"$new_app_name\""

echo "App name: $new_app_name"

# TODO: Exit if app name not found.

grep -FIr "$app_id_old" . | awk -F: '{print $1}' | xargs sed -i "s/$app_id_old/$app_id_new/g"

sed -i "s/$old_label/$new_label/g" android/app/src/main/AndroidManifest.xml

# TODO: Rename all directories with the old app name.
#
# android/app/src/main/java/com/occase/carway/MainActivity.java
# android/app/src/main/kotlin/com/occase/car/MainActivity.kt

