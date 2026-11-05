import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Lencana visual penanda mode demo / data simulasi lokal.
class DemoBadge extends StatelessWidget {
  final String label;

  const DemoBadge({
    super.key,
    this.label = 'Mode demo',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.demoBadgeBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.demoBadgeText.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline,
            size: 12,
            color: AppTheme.demoBadgeText,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.demoBadgeText,
            ),
          ),
        ],
      ),
    );
  }
}
