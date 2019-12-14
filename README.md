To run the emulator

   flutter emulators --launch Nexus_5X_API_28
   flutter run -d emulator-5554

To generate the asset files

```
   $ cd occase-config
   $ make carway
   $ cp tmp/ path-to-occcase-app/data
```

The font used in the icon was: Caesar Dressing.

To create an app with another app id substitute all occurrencies
of 

   $ grep -r com.occase.carway
   $ find . -name carway

with the new the new id. To change the name do it similar.

Notes
----------------------------------------------------------

Last time I tried to clone and run I had to add the file

   android/settings.gradle

A new file was generated called

   android/settings_aar.gradle

I added this to the project just in case won't be automaticaly generated
next time.

