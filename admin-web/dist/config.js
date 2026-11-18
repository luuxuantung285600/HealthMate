// Local emulators only. Cloud setup is documented in ../README.md.
window.HEALTHMATE_ADMIN_CONFIG = {
  firebase: { apiKey: 'demo-key', projectId: 'demo-healthmate-admin', authDomain: 'demo-healthmate-admin.firebaseapp.com' },
  emulators: { auth: 'http://127.0.0.1:9098', firestoreHost: '127.0.0.1', firestorePort: 8092 },
  // Free ExerciseDB media is for local noncommercial testing only.
  // Real Firebase on localhost requires this opt-in; hosted releases keep false.
  enableFreeExerciseMedia: false,
  statisticsMode: 'firestore',
  appCheckSiteKey: ''
};
