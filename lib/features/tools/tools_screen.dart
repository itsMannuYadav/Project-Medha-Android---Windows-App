import 'package:flutter/material.dart';

import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../fees/fees_screen.dart';
import '../homework/homework_screen.dart';
import '../library/library_screen.dart';
import '../report_card/report_card_screen.dart';
import '../syllabus/syllabus_screen.dart';
import '../timetable/timetable_screen.dart';
import 'class_timer_screen.dart';
import 'group_maker_screen.dart';
import 'name_picker_screen.dart';
import 'translate_simplify_screen.dart';

class _Tool {
  const _Tool(this.icon, this.title, this.subtitle, this.tint, {this.builder});
  final String icon;
  final String title;
  final String subtitle;
  final bool tint; // true = blue wash, false = amber wash
  final WidgetBuilder? builder;
}

final _dailyTools = [
  _Tool('clock', 'क्लास टाइमर', 'गतिविधि का समय तय करें', true, builder: (_) => const ClassTimerScreen()),
  _Tool('users_group', 'ग्रुप बनाएं', 'छात्रों के समूह तुरंत बनाएं', false, builder: (_) => const GroupMakerScreen()),
  _Tool('dice', 'नाम चुनें', 'बेतरतीब ढंग से छात्र चुनें', true, builder: (_) => const NamePickerScreen()),
  _Tool('translate', 'अनुवाद/सरल करें', 'कठिन पाठ को सरल भाषा में', false, builder: (_) => const TranslateSimplifyScreen()),
  _Tool('file_question', 'PDF से सवाल-जवाब', 'कोई भी दस्तावेज़ अपलोड करें', true),
  _Tool('help_circle', 'क्विज़ बनाएं', 'पल भर में प्रश्न-पत्र', false),
  _Tool('clipboard', 'पाठ योजना', 'पूरे सप्ताह की योजना', true),
  _Tool('form', 'फॉर्म किट', 'सूचना-पत्र, अनुरोध पत्र', false),
];

final _schoolTools = [
  _Tool('report', 'होमवर्क', 'दें और प्रगति देखें', true, builder: (_) => const HomeworkScreen()),
  _Tool('grid_calendar', 'समय सारणी', 'साप्ताहिक कक्षा सूची', false, builder: (_) => const TimetableScreen()),
  _Tool('report', 'रिपोर्ट कार्ड', 'सत्र के अंक', true, builder: (_) => const ReportCardScreen()),
  _Tool('book', 'ई-लाइब्रेरी', 'पढ़ने की सामग्री', false, builder: (_) => const LibraryScreen()),
  _Tool('book', 'पाठ्यक्रम', 'अध्याय व विषय-वस्तु', true, builder: (_) => const SyllabusScreen()),
  _Tool('receipt', 'फीस', 'भुगतान का रिकॉर्ड', false, builder: (_) => const FeesScreen()),
];

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        toolbarHeight: 66,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('टूल्स'),
            SizedBox(height: 2),
            Text('रोज़मर्रा के काम, कुछ ही टैप में', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: MedhaColors.inkSoft)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('स्कूल प्रबंधन', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.muted)),
          ),
          _ToolGrid(tools: _schoolTools),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text('रोज़मर्रा के टूल्स', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.muted)),
          ),
          _ToolGrid(tools: _dailyTools),
        ],
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({required this.tools});
  final List<_Tool> tools;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.98,
      children: tools.map((t) {
        return MedhaCard(
          padding: const EdgeInsets.all(15),
          onTap: () {
            if (t.builder != null) {
              Navigator.of(context).push(MaterialPageRoute(builder: t.builder!));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${t.title} — बैकएंड जुड़ने पर उपलब्ध होगा'), duration: const Duration(seconds: 2)),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: t.tint ? MedhaColors.primaryWash : MedhaColors.accentWash, borderRadius: BorderRadius.circular(10)),
                child: Center(child: MedhaIcon(t.icon, size: 18, color: t.tint ? MedhaColors.primary : MedhaColors.accentInk)),
              ),
              const SizedBox(height: 10),
              Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MedhaColors.ink)),
              const SizedBox(height: 2),
              Text(t.subtitle, style: const TextStyle(fontSize: 10.5, color: MedhaColors.muted)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
