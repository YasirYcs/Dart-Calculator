import 'dart:io';

void main() {
  print('Dart Calculator');
  print('Enter an expression, "help" for help, or "exit" to quit.');

  while (true) {
    stdout.write('> ');
    final input = stdin.readLineSync();
    if (input == null) {
      break;
    }

    final command = input.trim().toLowerCase();
    if (command.isEmpty) {
      continue;
    }
    if (command == 'exit' || command == 'quit') {
      break;
    }
    if (command == 'help') {
      print('Use +, -, *, /, %, parentheses, and decimal numbers.');
      print('Example: (12.5 + 3) * -2');
      continue;
    }

    try {
      final result = ExpressionParser(input).parse();
      print(_formatResult(result));
    } on FormatException catch (error) {
      print('Error: ${error.message}');
    }
  }
}

String _formatResult(double value) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  }
  return value.toString();
}

class ExpressionParser {
  ExpressionParser(this.input);

  final String input;
  int position = 0;

  double parse() {
    final result = _parseExpression();
    _skipWhitespace();
    if (position != input.length) {
      _fail('Unexpected character "${input[position]}".');
    }
    return result;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      _skipWhitespace();
      if (_match('+')) {
        value = _checked(value + _parseTerm());
      } else if (_match('-')) {
        value = _checked(value - _parseTerm());
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseUnary();
    while (true) {
      _skipWhitespace();
      if (_match('*')) {
        value = _checked(value * _parseUnary());
      } else if (_match('/')) {
        final divisor = _parseUnary();
        if (divisor == 0) {
          _fail('Cannot divide by zero.');
        }
        value = _checked(value / divisor);
      } else if (_match('%')) {
        final divisor = _parseUnary();
        if (divisor == 0) {
          _fail('Cannot use zero as the modulo divisor.');
        }
        value = _checked(value % divisor);
      } else {
        return value;
      }
    }
  }

  double _parseUnary() {
    _skipWhitespace();
    if (_match('+')) {
      return _parseUnary();
    }
    if (_match('-')) {
      return _checked(-_parseUnary());
    }
    return _parsePrimary();
  }

  double _parsePrimary() {
    _skipWhitespace();
    if (_match('(')) {
      final value = _parseExpression();
      _skipWhitespace();
      if (!_match(')')) {
        _fail('Expected a closing parenthesis.');
      }
      return value;
    }
    return _parseNumber();
  }

  double _parseNumber() {
    _skipWhitespace();
    final start = position;
    var hasDigit = false;
    var hasDecimalPoint = false;

    while (position < input.length) {
      final character = input[position];
      if (_isDigit(character)) {
        hasDigit = true;
        position++;
      } else if (character == '.' && !hasDecimalPoint) {
        hasDecimalPoint = true;
        position++;
      } else {
        break;
      }
    }

    if (!hasDigit) {
      _fail('Expected a number.');
    }
    return double.parse(input.substring(start, position));
  }

  double _checked(double value) {
    if (!value.isFinite) {
      _fail('Result is outside the supported numeric range.');
    }
    return value;
  }

  bool _match(String character) {
    if (position < input.length && input[position] == character) {
      position++;
      return true;
    }
    return false;
  }

  void _skipWhitespace() {
    while (position < input.length && input[position].trim().isEmpty) {
      position++;
    }
  }

  bool _isDigit(String character) =>
      character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57;

  Never _fail(String message) {
    throw FormatException(message, input, position);
  }
}
