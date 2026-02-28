import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A row of preset buttons for quick stock adjustments.
///
/// Provides +1, +5, +10, and -1 buttons. The [onAdjust] callback
/// receives the delta value when a button is pressed.
class StockAdjustmentButtons extends StatelessWidget {
  final void Function(int delta) onAdjust;

  const StockAdjustmentButtons({super.key, required this.onAdjust});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildButton('+1', 1, const Color(0xFF22C55E)),
        _buildButton('+5', 5, const Color(0xFF3B82F6)),
        _buildButton('+10', 10, const Color(0xFF6366F1)),
        _buildButton('-1', -1, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildButton(String label, int delta, Color color) {
    return ShadButton.outline(
      onPressed: () => onAdjust(delta),
      size: ShadButtonSize.sm,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
