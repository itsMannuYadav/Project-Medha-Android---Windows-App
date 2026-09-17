import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../data/student_models.dart';
import '../../data/student_repository.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  List<FeeRecord> _fees = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final fees = await ref.read(studentRepositoryProvider).getMyFees();
      if (mounted) setState(() { _fees = fees; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  double get _totalPaid => _fees.where((f) => f.isPaid).fold(0, (s, f) => s + f.amount);
  double get _totalDue => _fees.where((f) => !f.isPaid).fold(0, (s, f) => s + f.amount);
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: 'â‚¹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(
          title: 'Fees',
          subtitle: 'Your fee payment records',
        ),
        if (!_loading && _error == null && _fees.isNotEmpty)
          _FeeSummary(paid: _totalPaid, due: _totalDue, fmt: _fmt),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _fees.isEmpty
                      ? const EmptyState(
                          message: 'No fees records found',
                          icon: Icons.currency_rupee_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _fees.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) =>
                                _FeeCard(fee: _fees[i], fmt: _fmt),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _FeeSummary extends StatelessWidget {
  final double paid;
  final double due;
  final NumberFormat fmt;

  const _FeeSummary({required this.paid, required this.due, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.terracotta.withValues(alpha: 0.9), AppColors.earth],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              label: 'Paid',
              value: fmt.format(paid),
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.ivory.withValues(alpha: 0.3)),
          Expanded(
            child: _SummaryTile(
              label: 'Due',
              value: fmt.format(due),
              icon: Icons.pending_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.ivory.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.manrope(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ivory)),
        Text(label,
            style: GoogleFonts.manrope(
                fontSize: 12, color: AppColors.ivory.withValues(alpha: 0.75))),
      ],
    );
  }
}

class _FeeCard extends StatelessWidget {
  final FeeRecord fee;
  final NumberFormat fmt;

  const _FeeCard({required this.fee, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final statusColor = fee.isPaid
        ? AppColors.sage
        : fee.isOverdue
            ? AppColors.destructive
            : AppColors.gold;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              fee.isPaid ? Icons.check_rounded : Icons.currency_rupee_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.label,
                  style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                ),
                if (fee.dueDate != null)
                  Text(
                    'Due: ${_fmtDate(fee.dueDate)}',
                    style: GoogleFonts.manrope(
                        fontSize: 12, color: AppColors.mutedForeground),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(fee.amount),
                style: GoogleFonts.manrope(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  fee.status.toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
