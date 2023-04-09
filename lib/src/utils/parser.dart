/// Author: Lâm Thành Nhân (2023)

/// String parser, supports multiple lines
List<String> parseString(
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

  final List<String> listString = [];
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

    listString.add(
      isReversed
          ? text.substring(startIndex, endIndex + 1).split('').reversed.join()
          : text.substring(startIndex, endIndex + 1),
    );

    text = text.substring(endIndex);
  }

  return listString.reversed.toList();
}
