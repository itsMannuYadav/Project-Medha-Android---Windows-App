import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/fees_api.dart';
import '../../core/theme/medha_colors.dart';

class LogPaymentScreen extends StatefulWidget {
  const LogPaymentScreen({super.key, required this.studentId, required this.studentName});
  final String studentId;
  final String studentName;

  @override
  State<LogPaymentScreen> createState() => _LogPaymentScreenState();
}

class _LogPaymentScreenState extends State<LogPaymentScreen> {
  final _amount = TextEditingController();
  final _feeType = TextEditingController(text: 'ट्यूशन फीस');
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _feeType.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0 || _feeType.text.trim().isEmpty) {
      setState(() => _error = 'राशि और फीस का प्रकार भरें।');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FeesApi.log(
        studentId: widget.studentId,
        amount: amount,
        feeType: _feeType.text.trim(),
        paymentDate: _date,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: Text('भुगतान लॉग करें — ${widget.studentName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('राशि (₹)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
            const SizedBox(height: 6),
            TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 14),
            const Text('फीस का प्रकार', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
            const SizedBox(height: 6),
            TextField(controller: _feeType, decoration: const InputDecoration(hintText: 'जैसे ट्यूशन फीस, परीक्षा शुल्क')),
            const SizedBox(height: 14),
            const Text('तारीख', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
            const SizedBox(height: 6),
            OutlinedButton(onPressed: _pickDate, child: Text('${_date.day}/${_date.month}/${_date.year}')),
            const SizedBox(height: 14),
            const Text('टिप्पणी (वैकल्पिक)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
            const SizedBox(height: 6),
            TextField(controller: _note),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.danger)),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('लॉग करें'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
