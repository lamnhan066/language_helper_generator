import 'data_type.dart';

class ParsedData {
  final String text;
  final DataType type;

  ParsedData(this.text, this.type);

  @override
  String toString() => 'ParsedData(text: $text, type: $type)';

  ParsedData copyWith({
    String? text,
    DataType? type,
  }) {
    return ParsedData(
      text ?? this.text,
      type ?? this.type,
    );
  }
}
