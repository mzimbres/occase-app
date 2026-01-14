![alt text](https://github.com/mzimbres/occase-app/blob/master/graphic_feature.jpg?raw=true)

# Build instructions

To run the emulator

   flutter emulators --launch Nexus_5X_API_28
   flutter run -d emulator-5554

To just build the app

   flutter build apk --release --target-platform android-arm

To install the app

   $ flutter build apk --release --target-platform android-arm
   $ flutter install -d xxxx

To generate the asset files

```
   $ cd occase-config
   $ make carway
   $ cp tmp/ path-to-occcase-app/data
```

The font used in the icon was: Caesar Dressing.

To create an app with another app id substitute all occurrencies
of 

   $ grep -r occase.car.de
   $ find . -name carway

with the new id. To change the name do it similar.

App id and name
----------------------------------------------------------

The script change_id.sh can help changing the app id and name.

The google-services.json for the specific application id will be stored as
google-services.json.occase.car.de

Notes
----------------------------------------------------------

Last time I tried to clone and run I had to add the file

   android/settings.gradle

A new file was generated called

   android/settings_aar.gradle

I added this to the project just in case won't be automaticaly generated
next time.

- If there is any problem with the build after updating a plugin version we
  can try the following

  https://stackoverflow.com/questions/55399209/update-flutter-dependencies-in-pub-cache

Notifications
-------------------------------------------------------------

DATA='{"notification": {"body": "this is a body","title": "this is a title"}, "priority": "high", "data": {"click_action": "FLUTTER_NOTIFICATION_CLICK", "id": "1", "status": "done"}, "to": "<FCM TOKEN>"}' 

https://developers.google.com/web/fundamentals/primers/service-workers
https://developers.google.com/web/updates/2015/03/push-notifications-on-the-open-web
https://www.html5rocks.com/en/tutorials/workers/basics/
