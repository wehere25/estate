enum NotificationType {
  propertyListed,
  priceChange,
  statusChange,
  chat,
  system,
  reminder,
  custom,
  other;

  String toValue() {
    return toString().split('.').last;
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.toValue().toLowerCase() == value.toLowerCase(),
      orElse: () => NotificationType.other,
    );
  }
}
