import 'package:flutter/material.dart';
import 'package:formz/formz.dart';

enum ValidationError {
  empty('Field cannot be empty'),
  invalid('Invalid format'),
  tooShort('Too short'),
  tooLong('Too long'),
  invalidFormat('Invalid format'),
  weak('Password is too weak');

  final String message;
  const ValidationError(this.message);
}

/// Utility class for form field validation
class Validators {
  Validators._(); // Private constructor to prevent instantiation
  
  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  /// Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  /// Strong password validation
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    // Check for uppercase
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for lowercase
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for digits
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for special characters
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  /// Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }
  
  /// Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneRegExp = RegExp(r'^[0-9]{10}$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Enter a valid 10 digit phone number';
    }
    
    return null;
  }
  
  /// Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  /// URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    
    // Simple URL validation regex
    final urlRegExp = RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    );
    
    if (!urlRegExp.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  /// Not empty validation
  static String? validateNotEmpty(String? value, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage;
    }
    
    return null;
  }

  /// Number validation
  static String? validateNumber(String? value, String errorMessage) {
    if (value == null || value.isEmpty) {
      return errorMessage;
    }
    
    final cleanValue = value.replaceAll(',', '');
    if (double.tryParse(cleanValue) == null) {
      return 'Please enter a valid number';
    }
    
    return null;
  }

  /// Zip code validation
  static String? validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Postal/ZIP code is required';
    }
    
    final zipRegExp = RegExp(r'^[0-9]{6}$');
    if (!zipRegExp.hasMatch(value)) {
      return 'Enter a valid 6-digit postal code';
    }
    
    return null;
  }
}