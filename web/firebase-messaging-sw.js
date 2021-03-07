importScripts("https://www.gstatic.com/firebasejs/8.0.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.0.1/firebase-messaging.js");

firebase.initializeApp({
   apiKey: "AIzaSyAA4OutYOzvQGfdVYLaX6e6zz38XH_gMNw",
   authDomain: "react-native-firebase-testing.firebaseapp.com",
   projectId: "occase-a81ae",
   storageBucket: "occase-a81ae.appspot.com",
   messagingSenderId: "178977565766",
   appId: "1:178977565766:android:a6b51669806bf6fe91ee47",
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((m) => {
  console.log("onBackgroundMessage", m);
});
