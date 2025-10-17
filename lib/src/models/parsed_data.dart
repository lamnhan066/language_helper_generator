import 'data_type.dart';

class ParsedData {
  /// Text without quotes.
  final String text;

  /// Type of text.
  final DataType type;

  /// No formated text.
  final String noFormatedText;

  /// Equals to `parsedText.text == ''`.
  bool get isEmpty => text == '';

  ParsedData({
    required this.text,
    required this.type,
    required this.noFormatedText,
  });

  static ParsedData get empty =>
      ParsedData(text: '', type: DataType.normal, noFormatedText: '');

  @override
  String toString() =>
      'ParsedData(text: $text, type: $type, noFormatedText: $noFormatedText)';

  ParsedData copyWith({String? text, DataType? type, String? noFormatedText}) {
    return ParsedData(
      text: text ?? this.text,
      type: type ?? this.type,
      noFormatedText: noFormatedText ?? this.noFormatedText,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ParsedData &&
        other.type == type &&
        other.noFormatedText == noFormatedText;
  }

  @override
  int get hashCode => type.hashCode ^ noFormatedText.hashCode;
}
