import 'package:flutter/material.dart';

import '../models/visitor.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final VisitorStatus status;

  static Color colorFor(VisitorStatus status) {
    switch (status) {
      case VisitorStatus.registered:
        return const Color(0xFF1E88E5);
      case VisitorStatus.checkedIn:
        return const Color(0xFF2E7D32);
      case VisitorStatus.checkedOut:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Chip(
      label: Text(
        status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
    );
  }
}
