// lib/features/inventory/widgets/fruit_guide_card.dart
//
// NEW FILE. Bridges an inventory item to Modules 2, 4 and 5.
//
// THE PROBLEM THIS SOLVES:
// InventoryFruit carries the fruit's name as a plain String ("Banana"),
// but FruitDetailScreen needs a FruitType carrying the database
// fruit_type_id - every storage, nutrition and recipe row is keyed on
// that id. This card does the lookup once when it appears, then each
// row opens the guide on its own tab.

import 'package:flutter/material.dart';

import 'package:fruitripe/models/fruit_type.dart';
import 'package:fruitripe/models/inventory_fruit.dart';
import 'package:fruitripe/services/information_service.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/screens/fruit_detail_screen.dart';

class FruitGuideCard extends StatefulWidget {
  const FruitGuideCard({super.key, required this.item});

  final InventoryFruit item;

  @override
  State<FruitGuideCard> createState() => _FruitGuideCardState();
}

class _FruitGuideCardState extends State<FruitGuideCard> {
  final _service = InformationService();

  FruitType? _fruitType;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    try {
      final match = await _service.fetchFruitTypeByName(widget.item.fruitName);
      if (!mounted) return;
      setState(() {
        _fruitType = match;
        _loading = false;
        _error = match == null
            ? 'No guide for ${widget.item.fruitName} yet.'
            : null;
      });
    } on InformationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the fruit guide.';
      });
    }
  }

  void _open(FruitGuideTab tab) {
    final type = _fruitType;
    if (type == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FruitDetailScreen(
          fruitType: type,
          // Opens at the ripeness this fruit was scanned at, so the
          // advice matches the fruit actually sitting in the kitchen.
          stage: widget.item.ripenessStage,
          initialTab: tab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: Text(
              'FRUIT GUIDE',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E3F),
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: Color(0xFF5F7264)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF5F7264)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _lookup();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else ...[
              _row(
                icon: Icons.kitchen_outlined,
                title: 'Storage advice',
                subtitle: 'How to keep it fresh for longer',
                tab: FruitGuideTab.storage,
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFEDF2EB)),
              _row(
                icon: Icons.monitor_heart_outlined,
                title: 'Nutrition',
                subtitle: 'Calories, vitamins and macros',
                tab: FruitGuideTab.nutrition,
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFEDF2EB)),
              _row(
                icon: Icons.restaurant_menu,
                title: 'Recipes',
                subtitle: 'Ways to use it at this ripeness',
                tab: FruitGuideTab.recipes,
                last: true,
              ),
            ],
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String subtitle,
    required FruitGuideTab tab,
    bool last = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        bottom: last ? const Radius.circular(14) : Radius.zero,
      ),
      onTap: () => _open(tab),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1B5E3F)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3527),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF5F7264)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9DB09F)),
          ],
        ),
      ),
    );
  }
}