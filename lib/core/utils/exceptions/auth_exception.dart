class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthException('The email address is not valid.');
      case 'user-disabled':
        return AuthException('This user has been disabled.');
      case 'user-not-found':
        return AuthException('No user found with this email.');
      case 'wrong-password':
        return AuthException('The password is invalid for this email.');
      case 'email-already-in-use':
        return AuthException('This email is already in use.');
      case 'operation-not-allowed':
        return AuthException('This operation is not allowed.');
      case 'weak-password':
        return AuthException('The password provided is too weak.');
      case 'network-request-failed':
        return AuthException('A network error occurred. Check your connection.');
      case 'too-many-requests':
        return AuthException('Too many login attempts. Try again later.');
      case 'requires-recent-login':
        return AuthException('This operation requires recent authentication. Please log in again.');
      default:
        return AuthException('An error occurred: $code');
    }
  }
  
  @override
  String toString() => 'AuthException: $message';
}
