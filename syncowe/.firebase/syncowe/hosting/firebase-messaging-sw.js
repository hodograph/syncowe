// Please see this file for the latest firebase-js-sdk version:
// https://github.com/firebase/flutterfire/blob/master/packages/firebase_core/firebase_core_web/lib/src/firebase_sdk_version.dart
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyCvgIU03sFsLSGgauhDizv-vxlXl7yNQkY",
  authDomain: "syncowe.firebaseapp.com",
  projectId: "syncowe",
  storageBucket: "syncowe.appspot.com",
  messagingSenderId: "134068539303",
  appId: "1:134068539303:web:33ebf7c66900c1b9457082",
  measurementId: "G-E8CC4P7G7D"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});