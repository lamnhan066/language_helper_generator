import 'dart:math';

import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';

/// Author: Lâm Thành Nhân (2023)

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

  final List<ParsedData> listString = [];
  while (true) {
    final index = text.indexOf(tag);
    if (index == -1) break;

    String? quote;
    int startIndex = index + tag.length;
    int? endIndex;
    int countQuote = 0;
    for (int i = startIndex; i < text.length; i++) {
      if (quote == null) {
        if (text[i] == "'") {
          quote = "'";
        }
        if (text[i] == '"') {
          quote = '"';
        }

        // Ignore if there is something between the tag and the quote
        final textBetween = text.substring(startIndex, i).trim();
        if (quote != null && textBetween.isNotEmpty) {
          break;
        }

        if (quote != null) {
          countQuote++;
          startIndex = i;
        }
      } else {
        if (text[i] == quote) {
          // Get the character before the current quote
          final previousChar = isReversed
              ? text[min(i + 1, text.length - 1)]
              : text[max(0, i - 1)];
          // Is the character is the backslash
          final isBackslashedQuote = previousChar == '\\';

          // Ignore counting if it's a `\"` or `\'`
          if (!isBackslashedQuote) {
            endIndex = i;
            countQuote++;
          }
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

    // Ignore if there is variable inside the text
    if (_isContainVariable(parsedText)) {
      listString.add(ParsedData(parsedText, DataType.containsVariable));
    } else {
      listString.add(ParsedData(parsedText, DataType.normal));
    }

    text = text.substring(endIndex);
  }

  return isReversed ? listString.reversed.toList() : listString.toList();
}

bool _isContainVariable(String text) {
  final formated = text.replaceAll(r'\$', '');
  return formated.contains('\$');
}
