import 'package:flutter/material.dart';

import '/models/prediction.dart';

class LongevitySection extends StatelessWidget {
  final Prediction prediction;
  const LongevitySection({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final date = prediction.bestConsumeDate;
    final dateLabel = '${date.day}/${date.month}/${date.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LONGEVITY',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.schedule, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              prediction.daysUntilSpoil > 0
                  ? '${prediction.daysUntilSpoil} day${prediction.daysUntilSpoil == 1 ? '' : 's'} remaining'
                  : 'Already spoiled',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'Best before $dateLabel',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}