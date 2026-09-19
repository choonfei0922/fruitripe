import 'package:flutter/material.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/fruit_type.dart';
import 'package:fruitripe/services/information_service.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/screens/fruit_detail_screen.dart';

/// Route from a scan result into FR 2.1 (Storage), FR 4.1 (Nutrition)
/// and FR 5.1 (Recipe). Looks up fruit_type_id by name.
class FruitGuideButton extends StatefulWidget {
  const FruitGuideButton({
    super.key,
    required this.fruitTypeName,
    required this.stage,
  });

  final String fruitTypeName;

  final RipenessStage stage;

  @override
  State<FruitGuideButton> createState() => _FruitGuideButtonState();
}

class _FruitGuideButtonState extends State<FruitGuideButton> {
  final _service = InformationService();
  bool _busy = false;

  Future<void> _open() async {
    setState(() => _busy = true);

    try {
      final FruitType? match =
      await _service.fetchFruitTypeByName(widget.fruitTypeName);

      if (!mounted) return;
      setState(() => _busy = false);

      if (match == null) {
        // The scanner knows this fruit but the database has no
        // reference content for it yet.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No storage or recipe information for '
                  '${widget.fruitTypeName} yet.',
            ),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FruitDetailScreen(
            fruitType: match,
            stage: widget.stage,
          ),
        ),
      );
    } on InformationFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the fruit guide.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _open,
        icon: _busy
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.menu_book_outlined),
        label: Text(
          _busy ? 'Loading...' : 'Storage, Nutrition & Recipes',
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}