import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/data/models/user_dto.dart';
import '../../core/utils/exceptions/auth_exception.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserDto?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUserToDto(userCredential.user);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  Future<UserDto?> signUp(String email, String password) async {
    try {
      // Add reCAPTCHA verification
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: false, // Set to true only for testing
      );

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUserToDto(userCredential.user);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserDto?> getCurrentUser() async {
    final user = _auth.currentUser;
    return _mapFirebaseUserToDto(user);
  }

  UserDto? _mapFirebaseUserToDto(User? user) {
    if (user == null) return null;
    return UserDto(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
