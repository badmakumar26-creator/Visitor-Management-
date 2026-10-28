import 'package:flutter/material.dart';

enum CustomButtonStyle { filled, outlined }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = CustomButtonStyle.filled,
    this.loading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CustomButtonStyle style;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    if (style == CustomButtonStyle.outlined) {
      return OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: color == null ? null : OutlinedButton.styleFrom(foregroundColor: color),
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: color == null
          ? null
          : ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      child: child,
    );
  }
}
