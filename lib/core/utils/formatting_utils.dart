import 'package:intl/intl.dart';

class FormattingUtils {
  /// Formats a number as Indian Rupees (INR)
  /// Example output: ₹1,25,000 or ₹1.25 Cr or ₹12.50 Lakh
  static String formatIndianRupees(num amount) {
    // For values in crores (10 million and above)
    if (amount >= 10000000) {
      final crores = amount / 10000000;
      return '₹${crores.toStringAsFixed(crores.truncateToDouble() == crores ? 0 : 2)} Cr';
    }
    // For values in lakhs (100,000 and above)
    else if (amount >= 100000) {
      final lakhs = amount / 100000;
      return '₹${lakhs.toStringAsFixed(lakhs.truncateToDouble() == lakhs ? 0 : 2)} Lakh';
    }
    // For values less than 1 lakh
    else {
      // Use Indian number formatting with thousands separator
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    }
  }

  /// Formats a date to display format: dd MMM, yyyy (e.g., 01 Jan, 2023)
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM, yyyy').format(date);
  }

  /// Formats a date to a condensed format: dd/MM/yy (e.g., 01/01/23)
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yy').format(date);
  }

  /// Formats a date to include time: dd MMM, yyyy HH:mm (e.g., 01 Jan, 2023 14:30)
  static String formatDateWithTime(DateTime date) {
    return DateFormat('dd MMM, yyyy HH:mm').format(date);
  }

  /// Formats a timestamp as a relative time string (e.g., "2 days ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Formats phone numbers for display: +91 99999 99999
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length != 10) {
      return phoneNumber; // Return as-is if not a standard 10-digit number
    }
    return '+91 ${phoneNumber.substring(0, 5)} ${phoneNumber.substring(5)}';
  }

  /// Format area in square feet with appropriate unit
  static String formatArea(num area) {
    return '$area sq.ft.';
  }

  /// Formats a property area with unit
  static String formatPropertyArea(double area, {String unit = 'sq ft'}) {
    return '${NumberFormat('#,##0').format(area)} $unit';
  }

  /// Truncates a string if it's longer than the specified length
  static String truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
