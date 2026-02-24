/// Validation utility functions for form inputs
class Validators {
  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates phone number (numbers only, minimum 10 digits)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove common formatting characters
    final cleanedNumber = value.replaceAll(RegExp(r'[\s\-().]'), '');

    // Check if it contains only digits and + sign (for international format)
    if (!RegExp(r'^[\d+]+$').hasMatch(cleanedNumber)) {
      return 'Phone number can only contain digits, spaces, dashes, parentheses and +';
    }

    // Remove + if present for length check
    final digitsOnly = cleanedNumber.replaceAll('+', '');

    // Check minimum length (10 digits)
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    // Check maximum length (15 digits - international standard)
    if (digitsOnly.length > 15) {
      return 'Phone number must not exceed 15 digits';
    }

    return null;
  }

  /// Validates password (minimum 8 characters, includes uppercase, lowercase, number, special char)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Check for uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for special character
    if (!value.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:".,<>?/\\|~]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Simplified password validation (only minimum length requirement)
  static String? validatePasswordSimple(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    return null;
  }

  /// Validates name (not empty, minimum 2 characters)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    return null;
  }

  /// Validates OTP (6 digits)
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must be 6 digits';
    }

    return null;
  }
}
