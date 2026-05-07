import 'package:flutter/material.dart';

class DataFieldTile extends StatelessWidget {
  const DataFieldTile({
    required this.label,
    required this.value,
    required this.highlighted,
    required this.duration,
    required this.icon,
    required this.accentColor,
    this.labelColor,
    super.key,
  });

  final String label;
  final String value;
  final bool highlighted;
  final Duration duration;
  final IconData icon;
  final Color accentColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    const fieldTextGray = Color(0xFF667085);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFDFF4F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextFormField(
          readOnly: true,
          initialValue: value,
          style: const TextStyle(
            color: fieldTextGray,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: fieldTextGray,
              fontWeight: FontWeight.w600,
            ),
            floatingLabelStyle: TextStyle(
              color: fieldTextGray,
              fontWeight: FontWeight.w700,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
