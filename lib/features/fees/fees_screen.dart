import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/fees_api.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/roster_api.dart';
import '../../core/models/attendance.dart';
import '../../core/models/fee_payment.dart';
import '../../core/models/profile.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';
import 'log_payment_screen.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  bool get _isStudent => AppScope.of(context, listen: false).teacher?.role == 'student';
  bool get _isPrincipal => AppScope.of(context, listen: false).teacher?.role == 'principal';

  List<ProfileSubject> _gradeOptions = [];
  String? _gradeId;
  List<AttendanceStudent> _roster = [];
  AttendanceStudent? _selected;

  List<FeePayment> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final self = AppScope.of(context, listen: false).teacher!;
    if (_isStudent) {
      await _loadPayments(self.id);
      return;
    }
    try {
      final profile = await ProfileApi.get();
      final seen = <String>{};
      final grades = [for (final s in profile.subjects) if (seen.add(s.gradeId)) s];
      if (!mounted) return;
      setState(() => _gradeOptions = grades);
      if (grades.isNotEmpty) {
        await _selectGrade(grades.first.gradeId);
      } else {
        setState(() => _loading = false);
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _selectGrade(String gradeId) async {
    setState(() {
      _loading = true;
      _gradeId = gradeId;
      _selected = null;
    });
    try {
      final roster = await RosterApi.forGrade(gradeId);
      if (!mounted) return;
      setState(() {
        _roster = roster;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadPayments(String studentId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payments = await FeesApi.listFor(studentId);
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('फीस')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
              : _isStudent
                  ? _buildPayments()
                  : _buildStaffFlow(),
    );
  }

  Widget _buildStaffFlow() {
    return Column(
      children: [
        if (_gradeOptions.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _gradeOptions.map((g) => Padding(padding: const EdgeInsets.only(right: 8), child: PillChip(label: g.gradeLabel, selected: g.gradeId == _gradeId, onTap: () => _selectGrade(g.gradeId)))).toList()),
            ),
          ),
        Expanded(
          child: _selected == null
              ? (_roster.isEmpty
                  ? const Center(child: Text('इस कक्षा में स्वीकृत छात्र नहीं हैं।', style: TextStyle(color: MedhaColors.muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _roster.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final s = _roster[i];
                        return MedhaCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          onTap: () {
                            setState(() => _selected = s);
                            _loadPayments(s.studentId);
                          },
                          child: Row(children: [Expanded(child: Text(s.fullName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))), const MedhaIcon('chevron_right', size: 15, color: MedhaColors.muted)]),
                        );
                      },
                    ))
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
                      child: Row(
                        children: [
                          IconButton(icon: const MedhaIcon('chevron_left', size: 18, color: MedhaColors.ink), onPressed: () => setState(() => _selected = null)),
                          Expanded(child: Text(_selected!.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                          if (_isPrincipal)
                            TextButton.icon(
                              onPressed: () async {
                                final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => LogPaymentScreen(studentId: _selected!.studentId, studentName: _selected!.fullName)));
                                if (saved == true) _loadPayments(_selected!.studentId);
                              },
                              icon: const MedhaIcon('plus', size: 14, color: MedhaColors.primary),
                              label: const Text('लॉग करें', style: TextStyle(color: MedhaColors.primary)),
                            ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildPayments()),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPayments() {
    if (_payments.isEmpty) {
      return const Center(child: Text('अभी कोई भुगतान लॉग नहीं है।', style: TextStyle(color: MedhaColors.muted)));
    }
    final total = _payments.fold<double>(0, (sum, p) => sum + p.amount);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MedhaCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('कुल जमा', style: TextStyle(fontSize: 13, color: MedhaColors.muted)),
              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final p in _payments) ...[
          MedhaCard(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: MedhaColors.successWash, borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: MedhaIcon('receipt', size: 17, color: MedhaColors.successInk)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.feeType, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      Text('${p.paymentDate.day}/${p.paymentDate.month}/${p.paymentDate.year} · ${p.loggedByName}', style: const TextStyle(fontSize: 11, color: MedhaColors.muted)),
                    ],
                  ),
                ),
                Text('₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
