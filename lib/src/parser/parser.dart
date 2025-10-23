// Author: Lâm Thành Nhân (2023); Github: @lamnhan066

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';

import 'visitor.dart';

/// Parse the provided raw Dart [text].
List<ParsedData> parses(String rawText) {
  final ParseStringResult result = parseString(content: rawText);
  final CompilationUnit compilationUnit = result.unit;
  return parseCompilationUnit(compilationUnit);
}

/// Parse the provided [compilationUnit] using the analyzer AST.
List<ParsedData> parseCompilationUnit(CompilationUnit compilationUnit) {
  // A visitor that collects string literals
  var visitor = StringLiteralVisitor();
  compilationUnit.accept(visitor);

  return visitor.parsedData;
}
