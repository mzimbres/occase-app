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

