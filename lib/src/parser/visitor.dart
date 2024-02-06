import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';

class StringLiteralVisitor extends RecursiveAstVisitor<void> {
  final List<ParsedData> parsedData = [];

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'tr' && node.target != null) {
      ParsedData? parsedData = _parseExpression(node.target!);
      if (parsedData != null) {
        this.parsedData.add(parsedData);
      }
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'translate' && node.target != null) {
      final first = node.argumentList.arguments.first;

      ParsedData? parsedData = _parseExpression(first);
      if (parsedData != null) {
        this.parsedData.add(parsedData);
      }
    }

    if (['trT', 'trF', 'trP', 'trC'].contains(node.methodName.name) &&
        node.target != null) {
      ParsedData? parsedData = _parseExpression(node.target!);
      if (parsedData != null) {
        this.parsedData.add(parsedData);
      }
    }
    super.visitMethodInvocation(node);
  }

  ParsedData? _parseExpression(Expression node) {
    if (node is AdjacentStrings) {
      bool isContainsVariable = false;
      for (var stringNode in node.strings) {
        final parsedData = _parseStringLiteral(stringNode);
        if (parsedData?.type == DataType.containsVariable) {
          isContainsVariable = true;
          break;
        }
      }

      return _parseStringLiteral(node)?.copyWith(
        type: isContainsVariable ? DataType.containsVariable : null,
      );
    } else if (node is StringLiteral) {
      return _parseStringLiteral(node);
    }
    return null;
  }

  ParsedData? _parseStringLiteral(StringLiteral node) {
    ParsedData parsedData = ParsedData(
      text: node.toSource(),
      type: DataType.normal,
      noFormatedText: node.toSource(),
    );
    if (node is StringInterpolation) {
      parsedData = parsedData.copyWith(
        type: DataType.containsVariable,
        noFormatedText: node.stringValue,
      );
      return parsedData;
    } else {
      parsedData = parsedData.copyWith(
        noFormatedText: node.stringValue,
      );
    }
    return parsedData;
  }
}
