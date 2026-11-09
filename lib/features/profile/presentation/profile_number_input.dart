/// Keep stored precision when opening an editor. Display rounding must never
/// silently become a replacement value when the user only edits another field.
String profileNumberInput(double? value) {
  if (value == null) return '';
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}
