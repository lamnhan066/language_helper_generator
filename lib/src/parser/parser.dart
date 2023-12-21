// Author: Lâm Thành Nhân (2023); Github: @lamnhan066

import 'dart:math';

import 'package:language_helper_generator/src/models/parsed_data.dart';
import 'package:language_helper_generator/src/models/visitor.dart';

import 'visitor.dart';

/// Supported quotes
const supportedQuotes = ['"', "'"];

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
    bool ignore = false;
    for (int i = startIndex; i < text.length; i++) {
      if (quote == null) {
        // If the char next to the tag is not supported quotes and space
        // then it's not a text we need to parse.
        if (!supportedQuotes.contains(text[i]) && text[i] != ' ') {
          text = text.substring(i);
          ignore = true;
          break;
        }

        // Get the first quote.
        if (supportedQuotes.contains(text[i])) {
          quote = text[i];
        }

        // Ignore if there is something between the tag and the quote.
        final textBetween = text.substring(startIndex, i).trim();
        if (quote != null && textBetween.isNotEmpty) {
          text = text.substring(i);
          ignore = true;
          break;
        }

        // Set the start index of quote.
        if (quote != null) {
          countQuote++;
          startIndex = i;
        }
      } else {
        if (text[i] == quote) {
          // Get the character before the current quote.
          final previousChar = isReversed
              ? text[min(i + 1, text.length - 1)]
              : text[max(0, i - 1)];

          // Is the character is the backslash.
          final isBackslashedQuote = previousChar == '\\';

          // Ignore counting if it's a `\"` or `\'`.
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

    // Ignore the current loop and move to the next loop.
    if (ignore) continue;

    // Stop if there is no matched quote.
    if (endIndex == null) break;

    List<Visitor> visitors = [
      BaseTextAndRawTagVisitor(),
      TryToConvertToSingleQuoteVisitor(),
      ContainsVariableVisitor(),
    ];

    ParsedData parsedData = ParsedData.empty;
    for (final visitor in visitors) {
      final value = visitor.visit(
        text: text,
        parsedData: parsedData,
        startIndex: startIndex,
        endIndex: endIndex,
        isReversed: isReversed,
      );
      parsedData = value.parsedData;

      if (value.stop) break;
    }

    if (!parsedData.isEmpty) {
      listString.add(parsedData);
      text = text.substring(startIndex + parsedData.text.length);
    } else {
      text = text.substring(endIndex + 1);
    }
  }

  return isReversed ? listString.reversed.toList() : listString.toList();
}
