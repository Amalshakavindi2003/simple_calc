import 'package:flutter/material.dart';

import '../widgets/calc_button.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _display = '0';
  double? _first;
  String? _operator;
  bool _shouldClear = false;
  String _history = '';
  double _memory = 0;

  void _onNumberTap(String text) {
    setState(() {
      if (text == '.' && _display.contains('.')) {
        return;
      }

      if (_shouldClear || _display == '0') {
        _display = text;
        _shouldClear = false;
        return;
      }

      _display += text;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onPercentage() {
    setState(() {
      final value = double.tryParse(_display) ?? 0.0;
      _display = (value / 100).toString().replaceAll(RegExp(r'\.0+$'), '');
    });
  }

  void _onMemoryAdd() {
    final value = double.tryParse(_display) ?? 0.0;
    _memory += value;
    setState(() {
      _history = 'M+ ($_memory)';
    });
  }

  void _onMemorySubtract() {
    final value = double.tryParse(_display) ?? 0.0;
    _memory -= value;
    setState(() {
      _history = 'M- ($_memory)';
    });
  }

  void _onMemoryRecall() {
    setState(() {
      _display = _formatResult(_memory);
      _shouldClear = true;
      _history = 'Recalled: $_display';
    });
  }

  void _onMemoryClear() {
    setState(() {
      _memory = 0;
      _history = 'Memory cleared';
    });
  }

  void _onOperatorTap(String operation) {
    setState(() {
      _first = double.tryParse(_display) ?? 0.0;
      _operator = operation;
      _shouldClear = true;
      _history = '${_formatResult(_first ?? 0)} $operation';
    });
  }

  void _onEqualsTap() {
    final second = double.tryParse(_display) ?? 0.0;
    double result = 0.0;

    if (_operator == '+') result = (_first ?? 0) + second;
    if (_operator == '-') result = (_first ?? 0) - second;
    if (_operator == '*') result = (_first ?? 0) * second;
    if (_operator == '/') result = second == 0 ? double.nan : (_first ?? 0) / second;

    setState(() {
      final resultStr = result.isNaN ? 'Error' : _formatResult(result);
      _history = '${_formatResult(_first ?? 0)} $_operator $second = $resultStr';
      _display = resultStr;
      _operator = null;
      _first = null;
      _shouldClear = true;
    });
  }

  String _formatResult(double value) {
    final asText = value.toString();
    if (asText.endsWith('.0')) {
      return asText.substring(0, asText.length - 2);
    }
    if (asText.length > 10) {
      return value.toStringAsFixed(4).replaceAll(RegExp(r'\.0+$'), '');
    }
    return asText;
  }

  void _clearAll() {
    setState(() {
      _display = '0';
      _first = null;
      _operator = null;
      _shouldClear = false;
      _history = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // History & Memory Display
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[900],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _history.isEmpty ? 'Ready' : _history,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_memory != 0)
                    Text(
                      'Memory: ${_formatResult(_memory)}',
                      style: const TextStyle(color: Colors.orange, fontSize: 11),
                    ),
                ],
              ),
            ),

            // Main Display
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Text(
                  _display,
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Buttons
            Column(
              children: [
                // Memory buttons
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            backgroundColor: Colors.deepPurple[700],
                          ),
                          onPressed: _onMemoryAdd,
                          child: const Text('M+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            backgroundColor: Colors.deepPurple[700],
                          ),
                          onPressed: _onMemorySubtract,
                          child: const Text('M-', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            backgroundColor: Colors.deepPurple[700],
                          ),
                          onPressed: _onMemoryRecall,
                          child: const Text('MR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            backgroundColor: Colors.deepPurple[700],
                          ),
                          onPressed: _onMemoryClear,
                          child: const Text('MC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),

                // Utility buttons (Backspace, Percentage, etc)
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.grey[700],
                          ),
                          onPressed: _onBackspace,
                          child: const Text('⌫', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.grey[700],
                          ),
                          onPressed: _onPercentage,
                          child: const Text('%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    CalcButton(label: '÷', color: Colors.orange, onPressed: () => _onOperatorTap('/')),
                    CalcButton(label: 'C', color: Colors.red, onPressed: _clearAll),
                  ],
                ),

                // Row 1: 7, 8, 9
                Row(
                  children: [
                    CalcButton(label: '7', onPressed: () => _onNumberTap('7')),
                    CalcButton(label: '8', onPressed: () => _onNumberTap('8')),
                    CalcButton(label: '9', onPressed: () => _onNumberTap('9')),
                    CalcButton(label: '×', color: Colors.orange, onPressed: () => _onOperatorTap('*')),
                  ],
                ),

                // Row 2: 4, 5, 6
                Row(
                  children: [
                    CalcButton(label: '4', onPressed: () => _onNumberTap('4')),
                    CalcButton(label: '5', onPressed: () => _onNumberTap('5')),
                    CalcButton(label: '6', onPressed: () => _onNumberTap('6')),
                    CalcButton(label: '−', color: Colors.orange, onPressed: () => _onOperatorTap('-')),
                  ],
                ),

                // Row 3: 1, 2, 3
                Row(
                  children: [
                    CalcButton(label: '1', onPressed: () => _onNumberTap('1')),
                    CalcButton(label: '2', onPressed: () => _onNumberTap('2')),
                    CalcButton(label: '3', onPressed: () => _onNumberTap('3')),
                    CalcButton(label: '+', color: Colors.orange, onPressed: () => _onOperatorTap('+')),
                  ],
                ),

                // Row 4: 0, decimal, equals
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            backgroundColor: Colors.grey[800],
                          ),
                          onPressed: () => _onNumberTap('0'),
                          child: const Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    CalcButton(label: '.', onPressed: () => _onNumberTap('.')),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: _onEqualsTap,
                          child: const Text('=', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

