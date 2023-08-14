import 'parsed_data.dart';

/// Type of the parsed data
enum DataType {
  /// Normal text
  normal('Normal'),

  /// Text contains variable
  containsVariable('Contains variable'),

  /// Text is duplicated
  duplicated('Duplicated');

  /// Reason in text
  final String text;

  const DataType(this.text);

  /// Parse [text] to get the [DataType]
  static DataType parse(String text, List<ParsedData> listParsedData) {
    if (DataType._isContainVariable(text)) {
      return DataType.containsVariable;
    }

    for (final parsedData in listParsedData) {
      if (parsedData.text == text) return DataType.duplicated;
    }

    return normal;
  }

  static bool _isContainVariable(String text) {
    final formated = text.replaceAll(r'\$', '');
    return formated.contains('\$');
  }
}
