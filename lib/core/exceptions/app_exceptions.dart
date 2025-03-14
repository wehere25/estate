/// Base exception class for the application
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  
  AppException(this.message, {this.code, this.originalException});
  
  @override
  String toString() {
    if (code != null) {
      return 'AppException: [$code] $message';
    }
    return 'AppException: $message';
  }
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException(String message, {String? code, dynamic originalException}) 
    : super(message, code: code, originalException: originalException);
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic originalException}) 
    : super(message, code: code, originalException: originalException);
}

/// Database related exceptions
class DatabaseException extends AppException {
  DatabaseException(String message, {String? code, dynamic originalException}) 
    : super(message, code: code, originalException: originalException);
}
