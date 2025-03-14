class ValidationUtils {
  ValidationUtils._(); // Private constructor

  /// Validates that a field is not empty
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates that a field is a valid number
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }
    
    return null;
  }

  /// Validates that a field is a valid integer
  static String? validateInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid whole number';
    }
    
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    
    return null;
  }
}
