/// Author: Lâm Thành Nhân (2023)

import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';

/// String parser, supports multiple lines
List<ParsedData> parseString(
  String rawText, {
  String? startingTag,
  String? endingTag,
}) {
  assert(startingTag != null || endingTag != null);
  final isReversed = endingTag != null;

  final String tag;
  String text;
  if (isReversed) {
    tag = endingTag.split('').reversed.join();
    text = rawText.replaceAll('\n', '').split('').reversed.join();
  } else {
    tag = startingTag!;
    text = rawText.replaceAll('\n', '');
  }

  final List<ParsedData> listParsedData = [];
  while (true) {
    final index = text.indexOf(tag);
    if (index == -1) break;

    String? quote;
    int startIndex = index + tag.length;
    int? endIndex;
    int countQuote = 0;
    for (int i = startIndex; i < text.length; i++) {
      if (quote == null) {
        // print(text[i]);
        if (text[i] == "'") {
          quote = "'";
        }
        if (text[i] == '"') {
          quote = '"';
        }

        // Ignore if there is something between the tag and the quote
        if (quote != null && text.substring(startIndex, i).trim().isNotEmpty) {
          break;
        }

        if (quote != null) {
          countQuote++;
          startIndex = i;
        }
      } else {
        if (text[i] == quote) {
          endIndex = i;
          countQuote++;
        }

        if (endIndex != null &&
            text[i] != ' ' &&
            text[i] != quote &&
            countQuote.isEven) {
          break;
        }
      }
    }

    if (endIndex == null) break;

    final parsedText = isReversed
        ? text.substring(startIndex, endIndex + 1).split('').reversed.join()
        : text.substring(startIndex, endIndex + 1);

    // get data type
    var dataType = DataType.parse(parsedText, listParsedData);

    // If there is duplicated text in the reversed list, the current element in the list
    // will be changed to duplicated, so it will be ordered after the `parsedText`
    // in the last result.
    //
    // Ex:
    // listParsedData = [d, c, b, a]
    // parsedText = c
    // => listParsedData = [d, duplicated of  c, c, b, a, c]
    // => last result = [c, a, b, duplicated of c, d]
    //
    // The last result without this step = [duplicated of c, a, b, c, d]
    if (isReversed && dataType == DataType.duplicated) {
      // Change the type of the duplicated text in the list to duplicated
      for (int i = 0; i < listParsedData.length; i++) {
        final element = listParsedData[i];
        if (element.text == parsedText && element.type != DataType.duplicated) {
          listParsedData[i] = element.copyWith(type: DataType.duplicated);
        }
      }

      // Change the current parsed text type to normal
      dataType = DataType.normal;
    }

    listParsedData.add(ParsedData(parsedText, dataType));

    text = text.substring(endIndex);
  }

  return isReversed
      ? listParsedData.reversed.toList()
      : listParsedData.toList();
}
