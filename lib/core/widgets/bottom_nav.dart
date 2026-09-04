import 'package:flutter/material.dart';

import '../theme/medha_colors.dart';
import 'medha_icon.dart';

class MedhaNavItem {
  const MedhaNavItem(this.icon, this.label);
  final String icon;
  final String label;
}

const medhaNavItems = [
  MedhaNavItem('home', 'होम'),
  MedhaNavItem('modules', 'मॉड्यूल'),
  MedhaNavItem('tools_grid', 'टूल्स'),
  MedhaNavItem('calendar_check', 'उपस्थिति'),
  MedhaNavItem('user', 'प्रोफ़ाइल'),
];

/// The 5-tab bottom bar shared by Home, Modules, Tools, Attendance and
/// Profile — identical everywhere except which tab is active, matching the
/// canvas mockups.
class MedhaBottomNav extends StatelessWidget {
  const MedhaBottomNav({super.key, required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MedhaColors.surface,
        border: Border(top: BorderSide(color: MedhaColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(medhaNavItems.length, (i) {
            final item = medhaNavItems[i];
            final active = i == currentIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? MedhaColors.primaryWash : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: MedhaIcon(item.icon, size: 19, color: active ? MedhaColors.primary : MedhaColors.muted),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: active ? MedhaColors.primary : MedhaColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
