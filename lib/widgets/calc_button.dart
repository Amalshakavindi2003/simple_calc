import 'package:flutter/material.dart';

class CalcButton extends StatefulWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.foregroundColor,
    this.flex = 1,
    this.fontSize = 20,
    this.borderRadius = 22,
    this.padding = const EdgeInsets.all(6),
    this.height = 58,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final Color? foregroundColor;
  final int flex;
  final double fontSize;
  final double borderRadius;
  final EdgeInsets padding;
  final double height;

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final defaultBackground = brightness == Brightness.dark ? const Color(0xFF3C3C3C) : const Color(0xFF2B2B2B);
    final defaultForeground = Colors.white;
    final buttonColor = widget.color ?? defaultBackground;
    final foregroundColor = widget.foregroundColor ?? defaultForeground;
    final borderRadius = BorderRadius.circular(widget.borderRadius);

    return Expanded(
      flex: widget.flex,
      child: Padding(
        padding: widget.padding,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Material(
            color: buttonColor,
            elevation: _pressed ? 1 : 6,
            shadowColor: Colors.black45,
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              onTap: widget.onPressed,
              child: SizedBox(
                height: widget.height,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

