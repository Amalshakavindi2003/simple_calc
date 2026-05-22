import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/calc_button.dart';
import '../services/calculator_engine.dart';

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
  List<String> _historyList = [];
  bool _scientificMode = false;

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

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _historyList = prefs.getStringList('history') ?? [];
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', _historyList);
  }

  void _addHistoryEntry(String entry) {
    setState(() {
      _historyList.insert(0, entry);
      if (_historyList.length > 50) _historyList.removeLast();
    });
    _saveHistory();
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
      _addHistoryEntry(_history);
      _display = resultStr;
      _operator = null;
      _first = null;
      _shouldClear = true;
    });
  }

  void _applyUnary(String op) {
    final value = double.tryParse(_display) ?? 0.0;
    double res;
    String entry = '';
    if (op == 'sqrt') {
      res = math.sqrt(value);
      entry = '√($value) = ${_formatResult(res)}';
    } else if (op == 'sin') {
      res = math.sin(value);
      entry = 'sin($value) = ${_formatResult(res)}';
    } else if (op == 'cos') {
      res = math.cos(value);
      entry = 'cos($value) = ${_formatResult(res)}';
    } else if (op == 'tan') {
      res = math.tan(value);
      entry = 'tan($value) = ${_formatResult(res)}';
    } else if (op == 'x2') {
      res = value * value;
      entry = '$value² = ${_formatResult(res)}';
    } else {
      return;
    }
    setState(() {
      _display = _formatResult(res);
      _shouldClear = true;
      _history = entry;
      _addHistoryEntry(entry);
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
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Calc'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: Icon(_scientificMode ? Icons.calculate : Icons.science),
            onPressed: () => setState(() => _scientificMode = !_scientificMode),
            tooltip: 'Scientific mode',
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // History & Memory Display
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: _display));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                    },
                    child: Text(
                      _history.isEmpty ? 'Ready' : _history,
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[700], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Buttons
            Column(
              children: [
                // Memory buttons
                Row(
                  children: [
                    _smallPurpleButton('M+', _onMemoryAdd),
                    _smallPurpleButton('M-', _onMemorySubtract),
                    _smallPurpleButton('MR', _onMemoryRecall),
                    _smallPurpleButton('MC', _onMemoryClear),
                  ],
                ),

                // Utility buttons (Backspace, Percentage, etc)
                Row(
                  children: [
                    _smallGreyButton('⌫', _onBackspace),
                    _smallGreyButton('%', _onPercentage),
                    CalcButton(label: '÷', color: Colors.orange, onPressed: () => _onOperatorTap('/')),
                    CalcButton(label: 'C', color: Colors.red, onPressed: _clearAll),
                  ],
                ),

                if (_scientificMode)
                  Row(children: [
                    CalcButton(label: '√', onPressed: () => _applyUnary('sqrt')),
                    CalcButton(label: 'sin', onPressed: () => _applyUnary('sin')),
                    CalcButton(label: 'cos', onPressed: () => _applyUnary('cos')),
                    CalcButton(label: 'tan', onPressed: () => _applyUnary('tan')),
                  ]),

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
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                          ),
                          onPressed: () => _onNumberTap('0'),
                          child: Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

  Widget _smallPurpleButton(String label, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(12),
            backgroundColor: Colors.deepPurple[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _smallGreyButton(String label, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _historyList.clear();
                        });
                        _saveHistory();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear All'),
                    )
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _historyList.length,
                  itemBuilder: (context, index) {
                    final item = _historyList[index];
                    return ListTile(
                      title: Text(item),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                      },
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

