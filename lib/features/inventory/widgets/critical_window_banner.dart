import 'package:flutter/material.dart';

/// "Critical Window" alert. Red rather than amber now — at 24 hours out
/// this is the last useful warning, and amber read as advisory.
class CriticalWindowBanner extends StatelessWidget {
  const CriticalWindowBanner({
    super.key,
    required this.count,
    this.onTap,
  });

  final int count;
  final VoidCallback? onTap;

  static const _bg = Color(0xFFFBE7E4);
  static const _border = Color(0xFFF3C7C1);
  static const _accent = Color(0xFFC0392B);
  static const _body = Color(0xFF8C3A2F);

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final body = count == 1
        ? '1 item is approaching terminal spoilage within 24 hours.'
        : '$count items are approaching terminal spoilage within 24 hours.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Material(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Critical Window',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: _body,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Padding(
                    padding: EdgeInsets.only(left: 6, top: 6),
                    child: Icon(Icons.chevron_right, color: _accent, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}