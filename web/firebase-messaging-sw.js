importScripts(
  "https://www.gstatic.com/firebasejs/12.17.0/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/12.17.0/firebase-messaging-compat.js",
);

firebase.initializeApp({
  apiKey: "AIzaSyC62FKZk-sKyZtEC8ub_Pc_JkacX54tuyg",
  authDomain: "geriatriccare-2477d.firebaseapp.com",
  projectId: "geriatriccare-2477d",
  storageBucket: "geriatriccare-2477d.firebasestorage.app",
  messagingSenderId: "687836303569",
  appId: "1:687836303569:web:dc600def426fc5a12875f0",
});

firebase.messaging();
