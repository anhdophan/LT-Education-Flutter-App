import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CalendarPage extends StatelessWidget {
  final List studyDays;
  const CalendarPage({super.key, required this.studyDays});

  List<DateTime> _getWeekDays(DateTime ref) {
    int diff = ref.weekday - DateTime.monday;
    DateTime monday = ref.subtract(Duration(days: diff));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  static const List<String> weekDayLabels = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime lastWeek = now.subtract(const Duration(days: 7));
    DateTime nextWeek = now.add(const Duration(days: 7));
    List<List<DateTime>> weeks = [
      _getWeekDays(lastWeek),
      _getWeekDays(now),
      _getWeekDays(nextWeek),
    ];
    List<String> weekLabels = ["Last week", "This week", "Next week"];
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemCount: weeks.length,
          itemBuilder: (context, w) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekLabels[w],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Day of week labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: weekDayLabels
                          .map(
                            (label) => Expanded(
                              child: Center(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    // Dates
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final day = weeks[w][i];
                        final studyDay = studyDays.firstWhere(
                          (d) =>
                              d['date'] != null &&
                              DateTime.tryParse(d['date']) != null &&
                              DateUtils.isSameDay(
                                DateTime.parse(d['date']),
                                day,
                              ),
                          orElse: () => null,
                        );
                        final isToday = DateUtils.isSameDay(day, now);
                        return Expanded(
                          child: GestureDetector(
                            onTap: studyDay != null
                                ? () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Study Day'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Date: ${studyDay['date'] ?? ''}",
                                            ),
                                            Text(
                                              "Day: ${studyDay['dayOfWeek'] ?? ''}",
                                            ),
                                            Text(
                                              "Start: ${studyDay['startTime'] ?? ''}",
                                            ),
                                            Text(
                                              "End: ${studyDay['endTime'] ?? ''}",
                                            ),
                                            if (studyDay['className'] != null)
                                              Text(
                                                "Class: ${studyDay['className']}",
                                              ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? AppColors.primary.withOpacity(0.15)
                                          : studyDay != null
                                          ? Colors.green.withOpacity(0.15)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isToday
                                            ? AppColors.primary
                                            : studyDay != null
                                            ? Colors.green
                                            : Colors.transparent,
                                        width: isToday ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        Text(
                                          "${day.day}",
                                          style: TextStyle(
                                            color: isToday
                                                ? AppColors.primary
                                                : studyDay != null
                                                ? Colors.green[800]
                                                : AppColors.textDark,
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (studyDay != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
