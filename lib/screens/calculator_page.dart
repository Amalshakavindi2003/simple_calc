import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/calc_button.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  final String expression;
  final String result;
  final DateTime timestamp;

  String get displayText => '$expression = $result';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'expression': expression,
        'result': result,
        'timestamp': timestamp.toIso8601String(),
      };

  factory _HistoryEntry.fromJson(Map<String, dynamic> json) {
    return _HistoryEntry(
      expression: json['expression']?.toString() ?? '',
      result: json['result']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class _BinaryResult {
  const _BinaryResult(this.value);

  final double value;
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const String _historyStorageKey = 'calculator_history_v2';
  static const double _historyPanelWidth = 340;

  final FocusNode _focusNode = FocusNode(debugLabel: 'calculator-input-focus');

  String _display = '0';
  String _expressionPreview = 'Ready';
  double? _firstOperand;
  String? _operator;
  bool _shouldClearDisplay = false;
  bool _scientificMode = false;
  bool _historyPanelOpen = false;
  double _memory = 0;
  List<_HistoryEntry> _history = <_HistoryEntry>[];
  int _resultAnimationKey = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawHistory = prefs.getStringList(_historyStorageKey) ?? <String>[];
    final entries = <_HistoryEntry>[];

    for (final rawItem in rawHistory) {
      try {
        final decoded = jsonDecode(rawItem);
        if (decoded is Map<String, dynamic>) {
          entries.add(_HistoryEntry.fromJson(decoded));
        } else if (decoded is Map) {
          entries.add(_HistoryEntry.fromJson(decoded.cast<String, dynamic>()));
        }
      } catch (_) {
        // Ignore older/invalid entries and continue.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _history = entries.take(10).toList();
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyStorageKey,
      _history.take(10).map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  void _requestKeyboardFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _resetForError() {
    _display = 'Error';
    _expressionPreview = 'Invalid calculation';
    _firstOperand = null;
    _operator = null;
    _shouldClearDisplay = true;
  }

  double? _parseDisplay() {
    if (_display == 'Error') {
      return null;
    }

    return double.tryParse(_display.replaceAll(',', ''));
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Error';
    }

    final normalized = value.abs() < 1e-12 ? 0.0 : value;
    final rounded = normalized.roundToDouble();
    if ((normalized - rounded).abs() < 1e-10) {
      return _addGrouping(rounded.toInt().toString());
    }

    var text = normalized.toStringAsPrecision(12);
    if (text.contains('e') || text.contains('E')) {
      return text;
    }

    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return _addGrouping(text);
  }

  String _addGrouping(String numberText) {
    if (numberText.isEmpty || numberText == 'Error') {
      return numberText;
    }

    final negative = numberText.startsWith('-');
    final unsigned = negative ? numberText.substring(1) : numberText;
    final parts = unsigned.split('.');
    final integer = parts.first;
    if (integer.length < 4) {
      return numberText;
    }

    final grouped = integer.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final rebuilt = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
    return negative ? '-$rebuilt' : rebuilt;
  }

  String _operatorSymbol(String op) {
    switch (op) {
      case '+':
        return '+';
      case '-':
        return '−';
      case '*':
        return '×';
      case '/':
        return '÷';
      default:
        return op;
    }
  }

  _BinaryResult? _computeBinary(double first, String op, double second) {
    switch (op) {
      case '+':
        return _BinaryResult(first + second);
      case '-':
        return _BinaryResult(first - second);
      case '*':
        return _BinaryResult(first * second);
      case '/':
        if (second == 0) {
          return null;
        }
        return _BinaryResult(first / second);
      default:
        return null;
    }
  }

  void _recordHistory(String expression, String result) {
    final entry = _HistoryEntry(
      expression: expression,
      result: result,
      timestamp: DateTime.now(),
    );

    setState(() {
      _history = <_HistoryEntry>[entry, ..._history].take(10).toList();
      _historyPanelOpen = false;
    });
    _saveHistory();
  }

  void _appendInput(String value) {
    setState(() {
      if (_display == 'Error') {
        _display = '0';
        _expressionPreview = 'Ready';
        _firstOperand = null;
        _operator = null;
        _shouldClearDisplay = false;
      }

      if (value == '.' && _display.contains('.')) {
        return;
      }

      if (_shouldClearDisplay) {
        _display = value == '.' ? '0.' : value;
        _shouldClearDisplay = false;
        return;
      }

      if (_display == '0' && value != '.') {
        _display = value;
        return;
      }

      _display += value;
    });

    _requestKeyboardFocus();
  }

  void _backspace() {
    setState(() {
      if (_display == 'Error' || _shouldClearDisplay) {
        _display = '0';
        _shouldClearDisplay = false;
        return;
      }

      if (_display.length <= 1) {
        _display = '0';
      } else {
        _display = _display.substring(0, _display.length - 1);
      }
    });

    _requestKeyboardFocus();
  }

  void _percentage() {
    final value = _parseDisplay();
    if (value == null) {
      _resetForError();
    } else {
      setState(() {
        final result = value / 100;
        final resultText = _formatNumber(result);
        _display = resultText;
        _expressionPreview = '${_formatNumber(value)} % = $resultText';
        _shouldClearDisplay = true;
      });
    }

    _requestKeyboardFocus();
  }

  void _setBinaryOperator(String op) {
    final current = _parseDisplay();
    if (current == null) {
      setState(_resetForError);
      _requestKeyboardFocus();
      return;
    }

    setState(() {
      if (_firstOperand != null && _operator != null && !_shouldClearDisplay) {
        final intermediate = _computeBinary(_firstOperand!, _operator!, current);
        if (intermediate == null) {
          _resetForError();
          return;
        }

        _firstOperand = intermediate.value;
        _display = _formatNumber(intermediate.value);
      } else {
        _firstOperand = current;
      }

      _operator = op;
      _expressionPreview = '${_formatNumber(_firstOperand!)} ${_operatorSymbol(op)}';
      _shouldClearDisplay = true;
    });

    _requestKeyboardFocus();
  }

  void _calculate() {
    if (_operator == null || _firstOperand == null) {
      _requestKeyboardFocus();
      return;
    }

    final second = _parseDisplay();
    if (second == null) {
      setState(_resetForError);
      _requestKeyboardFocus();
      return;
    }

    final expression = '${_formatNumber(_firstOperand!)} ${_operatorSymbol(_operator!)} ${_formatNumber(second)}';
    final result = _computeBinary(_firstOperand!, _operator!, second);

    if (result == null) {
      setState(() {
        _display = 'Error';
        _expressionPreview = '$expression = Error';
        _firstOperand = null;
        _operator = null;
        _shouldClearDisplay = true;
      });
      _requestKeyboardFocus();
      return;
    }

    final resultText = _formatNumber(result.value);
    setState(() {
      _display = resultText;
      _expressionPreview = '$expression = $resultText';
      _firstOperand = null;
      _operator = null;
      _shouldClearDisplay = true;
      _resultAnimationKey++;
    });
    _recordHistory(expression, resultText);
    _requestKeyboardFocus();
  }

  void _applyUnary(String operation) {
    final value = _parseDisplay();
    if (value == null) {
      setState(_resetForError);
      _requestKeyboardFocus();
      return;
    }

    double? resultValue;
    String expression;

    switch (operation) {
      case 'sqrt':
        if (value < 0) {
          resultValue = null;
        } else {
          resultValue = math.sqrt(value);
        }
        expression = '√(${_formatNumber(value)})';
        break;
      case 'log':
        if (value <= 0) {
          resultValue = null;
        } else {
          resultValue = math.log(value) / math.ln10;
        }
        expression = 'log(${_formatNumber(value)})';
        break;
      case 'ln':
        if (value <= 0) {
          resultValue = null;
        } else {
          resultValue = math.log(value);
        }
        expression = 'ln(${_formatNumber(value)})';
        break;
      case 'sin':
        resultValue = math.sin(value * math.pi / 180);
        expression = 'sin(${_formatNumber(value)}°)';
        break;
      case 'cos':
        resultValue = math.cos(value * math.pi / 180);
        expression = 'cos(${_formatNumber(value)}°)';
        break;
      case 'tan':
        resultValue = math.tan(value * math.pi / 180);
        expression = 'tan(${_formatNumber(value)}°)';
        break;
      case 'square':
        resultValue = value * value;
        expression = '(${_formatNumber(value)})²';
        break;
      case 'cube':
        resultValue = value * value * value;
        expression = '(${_formatNumber(value)})³';
        break;
      case 'pi':
        resultValue = math.pi;
        expression = 'π';
        break;
      case 'e':
        resultValue = math.e;
        expression = 'e';
        break;
      default:
        return;
    }

    if (resultValue == null || resultValue.isNaN || resultValue.isInfinite) {
      setState(_resetForError);
      _requestKeyboardFocus();
      return;
    }

    final resultText = _formatNumber(resultValue);
    setState(() {
      _display = resultText;
      _expressionPreview = '$expression = $resultText';
      _firstOperand = null;
      _operator = null;
      _shouldClearDisplay = true;
      _resultAnimationKey++;
    });
    _recordHistory(expression, resultText);
    _requestKeyboardFocus();
  }

  void _clearAll() {
    setState(() {
      _display = '0';
      _expressionPreview = 'Ready';
      _firstOperand = null;
      _operator = null;
      _shouldClearDisplay = false;
      _resultAnimationKey++;
    });
    _requestKeyboardFocus();
  }

  void _toggleScientificMode() {
    setState(() {
      _scientificMode = !_scientificMode;
    });
    _requestKeyboardFocus();
  }

  void _toggleHistoryPanel() {
    setState(() {
      _historyPanelOpen = !_historyPanelOpen;
    });
    _requestKeyboardFocus();
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
      _historyPanelOpen = false;
    });
    _saveHistory();
    _requestKeyboardFocus();
  }

  void _restoreHistoryEntry(_HistoryEntry entry) {
    setState(() {
      _display = entry.result;
      _expressionPreview = entry.displayText;
      _firstOperand = null;
      _operator = null;
      _shouldClearDisplay = true;
      _historyPanelOpen = false;
      _resultAnimationKey++;
    });
    _requestKeyboardFocus();
  }

  Future<void> _copyResult() async {
    await Clipboard.setData(ClipboardData(text: _display));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result copied to clipboard')),
    );
    _requestKeyboardFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final logicalKey = event.logicalKey;
    final character = event.character;
    final ctrlPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    if (ctrlPressed && logicalKey == LogicalKeyboardKey.keyC) {
      _copyResult();
      return KeyEventResult.handled;
    }

    if (logicalKey == LogicalKeyboardKey.escape) {
      _clearAll();
      return KeyEventResult.handled;
    }

    if (logicalKey == LogicalKeyboardKey.backspace || logicalKey == LogicalKeyboardKey.delete) {
      _backspace();
      return KeyEventResult.handled;
    }

    if (logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter) {
      _calculate();
      return KeyEventResult.handled;
    }

    if (character != null && RegExp(r'^[0-9.]$').hasMatch(character)) {
      _appendInput(character);
      return KeyEventResult.handled;
    }

    switch (character) {
      case '+':
        _setBinaryOperator('+');
        return KeyEventResult.handled;
      case '-':
        _setBinaryOperator('-');
        return KeyEventResult.handled;
      case '*':
        _setBinaryOperator('*');
        return KeyEventResult.handled;
      case '/':
        _setBinaryOperator('/');
        return KeyEventResult.handled;
      case '=':
        _calculate();
        return KeyEventResult.handled;
      case '%':
        _percentage();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final panelWidth = math.min(
      _historyPanelWidth,
      MediaQuery.of(context).size.width * 0.88,
    );
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [Color(0xFF252525), Color(0xFF000000)]
          : const [Color(0xFFF9FAFC), Color(0xFFEAECEF)],
    );

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Simple Calc',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: isDark ? Colors.white : const Color(0xFF101114),
            ),
          ),
          centerTitle: true,
          toolbarHeight: 72,
          backgroundColor: isDark ? const Color(0xFF111317) : const Color(0xFFF7F8FC),
          foregroundColor: isDark ? Colors.white : const Color(0xFF101114),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          actions: [
            _buildTopBarAction(
              tooltip: _historyPanelOpen ? 'Close history' : 'Open history',
              icon: _historyPanelOpen ? Icons.chevron_right_rounded : Icons.history_rounded,
              onPressed: _toggleHistoryPanel,
              isDark: isDark,
            ),
            _buildTopBarAction(
              tooltip: _scientificMode ? 'Hide scientific mode' : 'Show scientific mode',
              icon: _scientificMode ? Icons.science_rounded : Icons.functions_rounded,
              onPressed: _toggleScientificMode,
              isDark: isDark,
              isActive: _scientificMode,
            ),
            _buildTopBarAction(
              tooltip: 'Copy result',
              icon: Icons.copy_rounded,
              onPressed: _copyResult,
              isDark: isDark,
            ),
            _buildTopBarAction(
              tooltip: 'Toggle theme',
              icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              onPressed: widget.onToggleTheme,
              isDark: isDark,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDisplayCard(context),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildKeypad(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_historyPanelOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleHistoryPanel,
                  child: Container(color: Colors.black54),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              top: 0,
              bottom: 0,
              right: _historyPanelOpen ? 0 : -panelWidth,
              width: panelWidth,
              child: _buildHistoryPanel(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 210,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: isDark ? const Color.fromRGBO(20, 20, 20, 0.92) : const Color.fromRGBO(255, 255, 255, 0.92),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, isDark ? 0.55 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _expressionPreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _toggleScientificMode,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    _scientificMode ? 'Scientific' : 'Basic',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFB8A9FF) : const Color(0xFF5C3FD0),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -180) {
                  _backspace();
                }
              },
              child: Align(
                alignment: Alignment.bottomRight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: FittedBox(
                    key: ValueKey<String>('$_resultAnimationKey-$_display'),
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _display,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF101010),
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.swipe_left_rounded,
                size: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(width: 6),
              Text(
                'Swipe left to delete last digit',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              if (_memory != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(108, 92, 231, isDark ? 0.28 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'M ${_formatNumber(_memory)}',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFD9D2FF) : const Color(0xFF5C3FD0),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow([
          CalcButton(
            label: 'M+',
            color: const Color(0xFF673AB7),
            onPressed: _memoryAdd,
            fontSize: 16,
          ),
          CalcButton(
            label: 'M-',
            color: const Color(0xFF673AB7),
            onPressed: _memorySubtract,
            fontSize: 16,
          ),
          CalcButton(
            label: 'MR',
            color: const Color(0xFF673AB7),
            onPressed: _memoryRecall,
            fontSize: 16,
          ),
          CalcButton(
            label: 'MC',
            color: const Color(0xFF673AB7),
            onPressed: _memoryClear,
            fontSize: 16,
          ),
        ]),
        _buildRow([
          CalcButton(label: '⌫', color: const Color(0xFF6B6B6B), onPressed: _backspace, fontSize: 18),
          CalcButton(label: '%', color: const Color(0xFF6B6B6B), onPressed: _percentage, fontSize: 18),
          CalcButton(label: '÷', color: const Color(0xFFFF9800), onPressed: () => _setBinaryOperator('/'), fontSize: 22),
          CalcButton(label: 'C', color: const Color(0xFFF44336), onPressed: _clearAll, fontSize: 22),
        ]),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.0, -0.15),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: !_scientificMode
                  ? const SizedBox.shrink(key: ValueKey<String>('scientific-off'))
                  : Column(
                      key: const ValueKey<String>('scientific-on'),
                      children: [
                        _buildRow([
                          CalcButton(label: 'sin', color: const Color(0xFF5D4037), onPressed: () => _applyUnary('sin'), fontSize: 17),
                          CalcButton(label: 'cos', color: const Color(0xFF5D4037), onPressed: () => _applyUnary('cos'), fontSize: 17),
                          CalcButton(label: 'tan', color: const Color(0xFF5D4037), onPressed: () => _applyUnary('tan'), fontSize: 17),
                          CalcButton(label: 'log', color: const Color(0xFF5D4037), onPressed: () => _applyUnary('log'), fontSize: 17),
                        ]),
                        _buildRow([
                          CalcButton(label: 'ln', color: const Color(0xFF5D4037), onPressed: () => _applyUnary('ln'), fontSize: 17),
                          CalcButton(label: '√', color: const Color(0xFF5D4037), onPressed: () => _applyUnary('sqrt'), fontSize: 22),
                          CalcButton(label: 'x²', color: const Color(0xFF5D4037), onPressed: () => _applyUnary('square'), fontSize: 20),
                          CalcButton(label: 'x³', color: const Color(0xFF5D4037), onPressed: () => _applyUnary('cube'), fontSize: 20),
                        ]),
                        _buildRow([
                          CalcButton(label: 'π', color: const Color(0xFF5D4037), onPressed: () => _applyUnary('pi'), fontSize: 24),
                          CalcButton(label: 'e', color: const Color(0xFF5D4037), onPressed: () => _applyUnary('e'), fontSize: 22),
                          const Expanded(child: SizedBox.shrink()),
                          const Expanded(child: SizedBox.shrink()),
                        ]),
                      ],
                    ),
            ),
          ),
        ),
        _buildRow([
          CalcButton(label: '7', onPressed: () => _appendInput('7')),
          CalcButton(label: '8', onPressed: () => _appendInput('8')),
          CalcButton(label: '9', onPressed: () => _appendInput('9')),
          CalcButton(label: '×', color: const Color(0xFFFF9800), onPressed: () => _setBinaryOperator('*'), fontSize: 22),
        ]),
        _buildRow([
          CalcButton(label: '4', onPressed: () => _appendInput('4')),
          CalcButton(label: '5', onPressed: () => _appendInput('5')),
          CalcButton(label: '6', onPressed: () => _appendInput('6')),
          CalcButton(label: '−', color: const Color(0xFFFF9800), onPressed: () => _setBinaryOperator('-'), fontSize: 22),
        ]),
        _buildRow([
          CalcButton(label: '1', onPressed: () => _appendInput('1')),
          CalcButton(label: '2', onPressed: () => _appendInput('2')),
          CalcButton(label: '3', onPressed: () => _appendInput('3')),
          CalcButton(label: '+', color: const Color(0xFFFF9800), onPressed: () => _setBinaryOperator('+'), fontSize: 22),
        ]),
        _buildRow([
          CalcButton(label: '0', flex: 2, onPressed: () => _appendInput('0'), fontSize: 22),
          CalcButton(label: '.', onPressed: () => _appendInput('.'), fontSize: 24),
          CalcButton(label: '=', color: const Color(0xFF2196F3), onPressed: _calculate, fontSize: 24),
        ]),
      ],
    );
  }

  Widget _buildRow(List<Widget> widgets) {
    return Row(
      children: widgets,
    );
  }

  Widget _buildTopBarAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    bool isActive = false,
  }) {
    final backgroundColor = isActive
        ? (isDark ? const Color(0xFF322B5E) : const Color(0xFFE0D8FF))
        : (isDark ? const Color(0xFF1E222B) : Colors.white);
    final borderColor = isActive
        ? (isDark ? const Color(0xFF6E5CF7) : const Color(0xFF8E7BFF))
        : (isDark ? Colors.white12 : Colors.black12);
    final iconColor = isActive
        ? (isDark ? const Color(0xFFD5CEFF) : const Color(0xFF5C3FD0))
        : (isDark ? Colors.white : const Color(0xFF1E2430));

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }

  void _memoryAdd() {
    final value = _parseDisplay();
    if (value == null) {
      _requestKeyboardFocus();
      return;
    }

    setState(() {
      _memory += value;
      _expressionPreview = 'Memory saved: M+ ${_formatNumber(value)}';
    });
    _requestKeyboardFocus();
  }

  void _memorySubtract() {
    final value = _parseDisplay();
    if (value == null) {
      _requestKeyboardFocus();
      return;
    }

    setState(() {
      _memory -= value;
      _expressionPreview = 'Memory saved: M- ${_formatNumber(value)}';
    });
    _requestKeyboardFocus();
  }

  void _memoryRecall() {
    setState(() {
      _display = _formatNumber(_memory);
      _expressionPreview = 'MR → ${_formatNumber(_memory)}';
      _shouldClearDisplay = true;
      _resultAnimationKey++;
    });
    _requestKeyboardFocus();
  }

  void _memoryClear() {
    setState(() {
      _memory = 0;
      _expressionPreview = 'Memory cleared';
    });
    _requestKeyboardFocus();
  }

  Widget _buildHistoryPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFFDFDFD),
      elevation: 20,
      shadowColor: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'History',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF111111),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clearHistory,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
                  IconButton(
                    tooltip: 'Close history',
                    onPressed: _toggleHistoryPanel,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
            Expanded(
              child: _history.isEmpty
                  ? Center(
                      child: Text(
                        'No calculations yet',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _history.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = _history[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _restoreHistoryEntry(entry),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F7),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.expression,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF101010),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.result,
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFB8A9FF) : const Color(0xFF5C3FD0),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

