import 'package:flutter/material.dart';

import 'package:fruitripe/models/fruit_reference.dart';

class StorageSection extends StatelessWidget {
  const StorageSection({super.key, required this.reference});

  final FruitReference reference;

  @override
  Widget build(BuildContext context) {
    final storage = reference.effectiveStorage;

    if (storage == null) {
      return _Empty(
        icon: Icons.kitchen_outlined,
        title: 'No storage advice yet',
        message: 'No guidance has been added for '
            '${reference.fruitType.name.toLowerCase()} at the '
            '${reference.stage.label.toLowerCase()} stage.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Shown when we fell back to the general row rather than a
        // stage-specific one, so the user knows why the advice is
        // less targeted.
        if (storage.isGeneral)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'General advice for ${reference.fruitType.name.toLowerCase()} — '
                  'no guidance specific to the ${reference.stage.label.toLowerCase()} '
                  'stage has been added yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // FR 2.1
        _AdviceCard(
          icon: Icons.thermostat,
          colour: const Color(0xFF1565C0),
          title: 'Where to keep it',
          body: storage.storageMethod,
        ),

        // FR 2.2
        if (storage.isolationMethod != null)
          _AdviceCard(
            icon: Icons.air,
            colour: const Color(0xFF6A1B9A),
            title: 'Keep it apart from',
            body: storage.isolationMethod!,
          ),

        // FR 2.3
        if (storage.ripeningControlTip != null)
          _AdviceCard(
            icon: Icons.speed,
            colour: const Color(0xFF2E7D32),
            title: 'Speed up or slow down',
            body: storage.ripeningControlTip!,
          ),

        if (storage.sourceReference != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_outlined, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Source: ${storage.sourceReference}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.icon,
    required this.colour,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colour.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: colour),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: const TextStyle(height: 1.5, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}