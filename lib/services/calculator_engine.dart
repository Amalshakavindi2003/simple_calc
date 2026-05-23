import 'package:math_expressions/math_expressions.dart';

class CalculatorEngine {
  /// Evaluate an expression string (supports × and ÷ replacements)
  static double? evaluate(String expression) {
    try {
      final exp = expression.replaceAll('×', '*').replaceAll('÷', '/');
      final parser = Parser();
      final parsed = parser.parse(exp);
      final result = parsed.evaluate(EvaluationType.REAL, ContextModel());
      if (result is num) return result.toDouble();
      return null;
    } catch (e) {
      return null;
    }
  }
}

