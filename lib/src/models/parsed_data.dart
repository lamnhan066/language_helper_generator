import 'data_type.dart';

class ParsedData {
  final String text;
  final DataType type;

  ParsedData(this.text, this.type);

  @override
  String toString() => 'ParsedData(text: $text, type: $type)';
}
