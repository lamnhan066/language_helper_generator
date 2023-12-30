// Author: Lâm Thành Nhân (2023); Github: @lamnhan066

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';

import 'visitor.dart';

/// String parser, supports multiple lines
List<ParsedData> parses(String rawText) {
  // Parse the code
  ParseStringResult result = parseString(content: rawText);
  CompilationUnit compilationUnit = result.unit;

  // A visitor that collects string literals
  var visitor = StringLiteralVisitor();
  compilationUnit.accept(visitor);

  return visitor.parsedData;
}
