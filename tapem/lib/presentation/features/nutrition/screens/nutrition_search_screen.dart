import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_product.dart';
import '../../../../domain/entities/nutrition/nutrition_recent_item.dart';
import '../providers/nutrition_providers.dart';

class NutritionSearchScreen extends HookConsumerWidget {
  const NutritionSearchScreen({super.key, required this.extra});

  final Map<String, dynamic> extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meal = extra['meal'];
    final dateKey = extra['dateKey'] as String? ?? '';
    final uid = extra['uid'] as String? ?? '';
    final returnProduct = extra['returnProduct'] as bool? ?? false;

    final queryCtrl = useTextEditingController();
    final query = useValueListenable(queryCtrl);
    final debouncedQuery = useState('');

    // Debounce
    useEffect(() {
      final text = queryCtrl.text.trim();
      Future.delayed(
        const Duration(milliseconds: 400),
        () {
          debouncedQuery.value = text;
        },
      );
      return null;
    }, [query.text]);

    final recents = ref.watch(nutritionRecentsProvider);

    void selectProduct(NutritionProduct product) {
      if (returnProduct) {
        context.pop<NutritionProduct>(product);
      } else {
        context.push('/nutrition/entry', extra: {
          'meal': meal,
          'dateKey': dateKey,
          'uid': uid,
          'product': product,
        });
      }
    }

    void selectRecent(NutritionRecentItem item) {
      selectProduct(NutritionProduct(
        name: item.name,
        kcalPer100: item.kcalPer100,
        proteinPer100: item.proteinPer100,
        carbsPer100: item.carbsPer100,
        fatPer100: item.fatPer100,
        barcode: item.barcode,
        updatedAt: DateTime.now(),
      ));
    }

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        backgroundColor: AppColors.surface900,
        surfaceTintColor: Colors.transparent,
        title: Text('PRODUKT SUCHEN', style: AppTextStyles.h3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.neonCyan,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: queryCtrl,
              autofocus: true,
              style: AppTextStyles.bodyLg,
              decoration: InputDecoration(
                hintText: 'Produktname eingeben...',
                hintStyle: AppTextStyles.bodySm,
                filled: true,
                fillColor: AppColors.surface600,
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: query.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => queryCtrl.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.surface500),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.surface500),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.neonCyan),
                ),
              ),
            ),
          ),
          const Gap(8),
          Expanded(
            child: debouncedQuery.value.length < 2
                ? _RecentsList(recents: recents, onSelect: selectRecent)
                : _SearchResults(
                    query: debouncedQuery.value,
                    onSelect: selectProduct,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Recents list ─────────────────────────────────────────────────────────────

class _RecentsList extends StatelessWidget {
  const _RecentsList({required this.recents, required this.onSelect});

  final List<NutritionRecentItem> recents;
  final void Function(NutritionRecentItem) onSelect;

  @override
  Widget build(BuildContext context) {
    if (recents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, color: AppColors.textDisabled, size: 48),
            const Gap(12),
            Text(
              'Noch keine Produkte geloggt.',
              style: AppTextStyles.bodySm,
            ),
            const Gap(4),
            Text(
              'Suche nach einem Produkt oben.',
              style: AppTextStyles.bodySm,
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const Gap(4),
        Text(
          'ZULETZT VERWENDET',
          style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary),
        ),
        const Gap(8),
        ...recents.map(
          (item) => _ProductTile(
            name: item.name,
            kcalPer100: item.kcalPer100,
            proteinPer100: item.proteinPer100,
            carbsPer100: item.carbsPer100,
            fatPer100: item.fatPer100,
            onTap: () => onSelect(item),
          ),
        ),
      ],
    );
  }
}

// ─── Search results ───────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.onSelect});

  final String query;
  final void Function(NutritionProduct) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(nutritionProductSearchProvider(query));
    return results.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.neonCyan),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const Gap(8),
            Text(
              'Suche fehlgeschlagen.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off, color: AppColors.textDisabled, size: 48),
                const Gap(12),
                Text(
                  'Kein Ergebnis für "$query".',
                  style: AppTextStyles.bodySm,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: products.length,
          itemBuilder: (context, i) {
            final p = products[i];
            return _ProductTile(
              name: p.name,
              kcalPer100: p.kcalPer100,
              proteinPer100: p.proteinPer100,
              carbsPer100: p.carbsPer100,
              fatPer100: p.fatPer100,
              onTap: () => onSelect(p),
            );
          },
        );
      },
    );
  }
}

// ─── Product tile ─────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.name,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    required this.onTap,
  });

  final String name;
  final int kcalPer100;
  final int proteinPer100;
  final int carbsPer100;
  final int fatPer100;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyLg,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Wrap(
                    spacing: 10,
                    children: [
                      _MacroLabel('${kcalPer100} kcal', Colors.orangeAccent),
                      _MacroLabel('P: ${proteinPer100}g', Colors.blueAccent),
                      _MacroLabel('K: ${carbsPer100}g', Colors.amberAccent),
                      _MacroLabel('F: ${fatPer100}g', Colors.lightGreenAccent),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(8),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _MacroLabel extends StatelessWidget {
  const _MacroLabel(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelSm.copyWith(color: color),
    );
  }
}
