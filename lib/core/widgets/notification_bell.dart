import 'package:flutter/material.dart';

import '../api/notifications_api.dart';
import '../theme/medha_colors.dart';
import '../../features/notifications/notifications_screen.dart';
import 'medha_icon.dart';

/// A bell icon with a live unread-count badge. Refetches whenever it's
/// rebuilt with a new key and after returning from the notifications list
/// (so marking things read there clears the badge here without a manual
/// refresh gesture).
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final count = await NotificationsApi.unreadCount();
      if (mounted) setState(() => _unread = count);
    } catch (_) {
      // silent -- a stale/missing badge isn't worth surfacing an error for
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: _open,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const MedhaIcon('bell', size: 19, color: MedhaColors.inkSoft),
            if (_unread > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 15),
                  decoration: const BoxDecoration(color: MedhaColors.danger, shape: BoxShape.circle),
                  child: Text(
                    _unread > 9 ? '9+' : '$_unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
