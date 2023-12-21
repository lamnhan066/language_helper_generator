import '../models/data_type.dart';
import '../models/parsed_data.dart';
import '../models/visitor.dart';

class BaseTextAndRawTagVisitor implements Visitor {
  /// Parse the base parsed text.
  const BaseTextAndRawTagVisitor();

  @override
  VisitorValue visit({
    required ParsedData parsedData,
    required String text,
    required int startIndex,
    required int endIndex,
    required bool isReversed,
  }) {
    String parsedText = isReversed
        ? text.substring(startIndex, endIndex + 1).split('').reversed.join()
        : text.substring(startIndex, endIndex + 1);

    bool isRawText = false;
    if (isReversed) {
      if (endIndex + 1 < text.length && text[endIndex + 1] == 'r') {
        isRawText = true;
      }
    } else {
      if (startIndex - 1 > 0 && text[startIndex - 1] == 'r') {
        isRawText = true;
      }
    }

    return VisitorValue(
      parsedData: parsedData.copyWith(
        text: parsedText,
        hasRawTag: isRawText,
      ),
    );
  }
}

class TryToConvertToSingleQuoteVisitor implements Visitor {
  TryToConvertToSingleQuoteVisitor();

  @override
  VisitorValue visit({
    required ParsedData parsedData,
    required String text,
    required int startIndex,
    required int endIndex,
    required bool isReversed,
  }) {
    String parsedText = parsedData.text;

    bool ableToConvert = true;
    if (parsedText.startsWith('"')) {
      int i = 1;
      while (i < parsedText.length - 2) {
        if (parsedText[i] == "'" && parsedText[i - 1] != r'\') {
          ableToConvert = false;
        }
        i++;
      }
    }

    if (ableToConvert) {
      if (parsedText.startsWith('"""')) {
        parsedText = "'''${parsedText.substring(3, parsedText.length - 3)}'''";
      } else {
        parsedText = "'${parsedText.substring(1, parsedText.length - 1)}'";
      }
    }

    return VisitorValue(
      parsedData: parsedData.copyWith(text: parsedText),
    );
  }
}

class ContainsVariableVisitor implements Visitor {
  const ContainsVariableVisitor();

  @override
  VisitorValue visit({
    required ParsedData parsedData,
    required String text,
    required int startIndex,
    required int endIndex,
    required bool isReversed,
  }) {
    return VisitorValue(
      parsedData: parsedData.copyWith(
        type: _isContainVariable(parsedData.text)
            ? DataType.containsVariable
            : DataType.normal,
      ),
    );
  }

  bool _isContainVariable(String text) {
    // Raw text does not need to be checked.
    if (text.startsWith('r')) return false;

    final formated = text.replaceAll(r'\$', '');
    return formated.contains('\$');
  }
}
