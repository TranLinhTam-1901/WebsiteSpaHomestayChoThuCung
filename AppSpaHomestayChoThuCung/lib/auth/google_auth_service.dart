import 'package:firebase_auth/firebase_auth.dart';

class GoogleAuthService {
  static Future<UserCredential> signInWithGoogle() async {
    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    googleProvider.addScope('email');
    googleProvider.setCustomParameters({
      'prompt': 'select_account'
    });

    return await FirebaseAuth.instance.signInWithPopup(googleProvider);
  }
}
