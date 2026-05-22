import 'package:flutter/material.dart';

import 'screens/calculator_page.dart';

class CalcApp extends StatelessWidget {
  const CalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Simple Calc',
      debugShowCheckedModeBanner: false,
      home: CalculatorPage(),
    );
  }
}

