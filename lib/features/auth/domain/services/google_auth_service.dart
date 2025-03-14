import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/utils/debug_logger.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  GoogleAuthService({
    GoogleSignIn? googleSignIn,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  Future<firebase_auth.User?> signInWithGoogle() async {
    try {
      DebugLogger.info('Starting Google Sign-In process');
      
      // Start Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        DebugLogger.info('Google Sign In cancelled by user');
        return null;
      }

      // Get auth details from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      DebugLogger.info('Got Google auth credentials');

      // Create Firebase credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      DebugLogger.info('Attempting Firebase direct Google auth');
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      return userCredential.user;
    } catch (e) {
      DebugLogger.error('Google sign in failed', e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
      ]);
    } catch (e) {
      DebugLogger.error('Error signing out from Google', e);
      rethrow;
    }
  }
}
