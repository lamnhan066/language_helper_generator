import 'parsed_data.dart';

class VisitorValue {
  /// Parsed text.
  final ParsedData parsedData;
  // Stop current visit loop when this value is `true`.
  final bool stop;

  VisitorValue({
    required this.parsedData,
    this.stop = false,
  });
}

abstract class Visitor {
  const Visitor();

  /// Visit the current parsing text. We focus on [text] between [startIndex] and
  /// [endIndex], which is [isReversed] or not. The [parsedData] is the data
  /// that we will get from the previous visitor.
  ///
  /// The first [parsedData] is usually generated by [BaseParserVisitor].
  VisitorValue visit({
    required ParsedData parsedData,
    required String text,
    required int startIndex,
    required int endIndex,
    required bool isReversed,
  });
}