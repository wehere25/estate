
import 'package:flutter/material.dart';

class AuthServiceHelpers {
  /// Validates an email and returns user-friendly error messages
  static EmailValidationResult validateEmailFormat(String email) {
    email = email.trim();
    
    if (email.isEmpty) {
      return EmailValidationResult(false, "Email cannot be empty");
    }
    
    if (!email.contains('@')) {
      return EmailValidationResult(false, "Email must include the @ symbol");
    }
    
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) {
      return EmailValidationResult(false, "Email must have content before the @ symbol");
    }
    
    final domain = parts[1];
    if (!domain.contains('.')) {
      return EmailValidationResult(false, "Email domain must include a dot (e.g., .com)");
    }
    
    final domainParts = domain.split('.');
    if (domainParts.last.isEmpty || domainParts.last.length < 2) {
      return EmailValidationResult(false, "Email must end with a valid domain extension");
    }
    
    // If all checks pass
    return EmailValidationResult(true, null);
  }
}

class EmailValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  EmailValidationResult(this.isValid, this.errorMessage);
}
