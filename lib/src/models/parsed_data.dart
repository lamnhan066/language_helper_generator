import 'data_type.dart';

class ParsedData {
  /// Text without quotes.
  final String text;

  /// Type of text.
  final DataType type;

  /// Have a `r` (raw text) tag.
  final bool hasRawTag;

  /// Get full text (includes raw text tag).
  String get fullText {
    String r = hasRawTag ? 'r' : '';
    return '$r$text';
  }

  /// Equals to `parsedText.text == ''`.
  bool get isEmpty => text == '';

  ParsedData(this.text, this.type, [this.hasRawTag = false]);

  static ParsedData get empty => ParsedData('', DataType.normal);

  @override
  String toString() =>
      'ParsedData(text: $text, type: $type, isRawText: $hasRawTag)';

  ParsedData copyWith({
    String? text,
    DataType? type,
    bool? hasRawTag,
  }) {
    return ParsedData(
      text ?? this.text,
      type ?? this.type,
      hasRawTag ?? this.hasRawTag,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ParsedData && other.text == text && other.type == type;
  }

  @override
  int get hashCode => text.hashCode ^ type.hashCode;
}
