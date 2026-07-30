import 'package:flutter/material.dart';

class CriticalWindowBanner extends StatelessWidget {
  const CriticalWindowBanner({
    super.key,
    required this.count,
    this.onTap,
  });

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final label = count == 1
        ? '1 item is expiring within 24 hours'
        : '$count items are expiring within 24 hours';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFFDF3E7),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8933D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled,
                    color: Color(0xFFC9741F), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A4B12),
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, color: Color(0xFFC9741F)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
