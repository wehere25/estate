enum NotificationType {
  newProperty,
  priceUpdate,
  statusChange,
  reminder,
  custom;

  String toValue() {
    return toString().split('.').last;
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.toValue() == value,
      orElse: () => NotificationType.custom,
    );
  }
}
