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

  void _onNumberTap(String text) {
    setState(() {
      if (_shouldClear || _display == '0') {
        _display = text;
        _shouldClear = false;
        return;
      }

      if (text == '.' && _display.contains('.')) {
        return;
      }

      _display += text;
    });
  }

  void _onOperatorTap(String operation) {
    setState(() {
      _first = double.tryParse(_display) ?? 0.0;
      _operator = operation;
      _shouldClear = true;
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
      _display = result.isNaN ? 'Error' : _formatResult(result);
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
    return asText;
  }

  void _clearAll() {
    setState(() {
      _display = '0';
      _first = null;
      _operator = null;
      _shouldClear = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Text(
                  _display,
                  style: const TextStyle(color: Colors.white, fontSize: 48),
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    CalcButton(label: '7', onPressed: () => _onNumberTap('7')),
                    CalcButton(label: '8', onPressed: () => _onNumberTap('8')),
                    CalcButton(label: '9', onPressed: () => _onNumberTap('9')),
                    CalcButton(
                      label: '/',
                      color: Colors.orange,
                      onPressed: () => _onOperatorTap('/'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    CalcButton(label: '4', onPressed: () => _onNumberTap('4')),
                    CalcButton(label: '5', onPressed: () => _onNumberTap('5')),
                    CalcButton(label: '6', onPressed: () => _onNumberTap('6')),
                    CalcButton(
                      label: '*',
                      color: Colors.orange,
                      onPressed: () => _onOperatorTap('*'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    CalcButton(label: '1', onPressed: () => _onNumberTap('1')),
                    CalcButton(label: '2', onPressed: () => _onNumberTap('2')),
                    CalcButton(label: '3', onPressed: () => _onNumberTap('3')),
                    CalcButton(
                      label: '-',
                      color: Colors.orange,
                      onPressed: () => _onOperatorTap('-'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    CalcButton(label: '0', onPressed: () => _onNumberTap('0')),
                    CalcButton(label: '.', onPressed: () => _onNumberTap('.')),
                    CalcButton(label: 'C', color: Colors.red, onPressed: _clearAll),
                    CalcButton(
                      label: '+',
                      color: Colors.orange,
                      onPressed: () => _onOperatorTap('+'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: _onEqualsTap,
                          child: const Text('=', style: TextStyle(fontSize: 24)),
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

