import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_copy.dart';
import '../providers/locale_provider.dart';

/// Mirrors components/app/language-toggle.tsx exactly: a bordered pill with
/// `bg-background` container, active option gets `bg-accent` +
/// `text-accent-foreground` (ink) — NOT a terracotta-filled pill. Only two
/// options (EN / हिं); see AppLocale's doc comment for why.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AppLocale.all.map((l) {
          final active = l.code == current;
          return GestureDetector(
            onTap: () => ref.read(localeProvider.notifier).setLocale(l.code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l.shortLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                  color: active ? AppColors.accentForeground : AppColors.mutedForeground,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
