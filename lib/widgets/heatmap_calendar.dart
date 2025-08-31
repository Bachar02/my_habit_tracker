// lib/widgets/heatmap_calendar.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/date_utils.dart' as date_utils;

class HeatmapCalendar extends StatelessWidget {
  final Map<String, int> completionData;
  final int maxCompletions;
  final int year;

  const HeatmapCalendar({
    Key? key,
    required this.completionData,
    required this.maxCompletions,
    required this.year,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$year Activity',
            style: Theme
                .of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${_getTotalCompletions()} habits completed this year',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          _buildHeatmap(context),
          const SizedBox(height: 16),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);

    // Calculate weeks needed
    final totalDays = lastDay
        .difference(firstDay)
        .inDays + 1;
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday
    final weeks = ((totalDays + startWeekday) / 7).ceil();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildMonthHeaders(weeks),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeekdayLabels(),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 108, // 7 days * 15px + spacing
                  child: Row(
                    children: List.generate(weeks, (weekIndex) {
                      return Padding(
                        padding: EdgeInsets.only(right: 2),
                        child: Column(
                          children: List.generate(7, (dayIndex) {
                            final dayOffset = weekIndex * 7 + dayIndex -
                                startWeekday;

                            if (dayOffset < 0 || dayOffset >= totalDays) {
                              return Container(
                                width: 12,
                                height: 12,
                                margin: EdgeInsets.all(1),
                              );
                            }

                            final date = firstDay.add(
                                Duration(days: dayOffset));
                            final dateStr = date_utils.DateUtils
                                .formatDateForApi(date);
                            final completions = completionData[dateStr] ?? 0;
                            final isToday = date_utils.DateUtils.isSameDay(
                                date, DateTime.now());

                            return GestureDetector(
                              onTap: () =>
                                  _showDayDetails(context, date, completions),
                              child: Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: _getColorForCompletions(completions),
                                  borderRadius: BorderRadius.circular(2),
                                  border: isToday
                                      ? Border.all(
                                      color: Colors.black, width: 1.5)
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeaders(int weeks) {
    final monthWidgets = <Widget>[];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    // Track which months we've already added
    final addedMonths = <int>{};

    for (int week = 0; week < weeks; week++) {
      final weekDate = DateTime(year, 1, 1).add(Duration(days: week * 7));

      // Only add month label if it's the first week of the month or we haven't added this month yet
      if (weekDate.day <= 7 && !addedMonths.contains(weekDate.month)) {
        addedMonths.add(weekDate.month);

        monthWidgets.add(
          Positioned(
            left: week * 14.0,
            child: Text(
              monthNames[weekDate.month - 1],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      }
    }

    return Container(
      height: 20,
      margin: const EdgeInsets.only(left: 20),
      // Match the width of weekday labels
      child: Stack(
        children: monthWidgets,
      ),
    );
  }

  int _getTotalCompletions() {
    return completionData.values.fold(0, (sum, count) => sum + count);
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        SizedBox(width: 8),
        ...List.generate(5, (index) {
          return Container(
            width: 12,
            height: 12,
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getColorForCompletions(index),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        SizedBox(width: 8),
        Text('More', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Column(
      children: weekdays.map((day) {
        return Container(
          width: 12,
          height: 12,
          margin: EdgeInsets.all(1),
          child: Center(
            child: Text(
              day,
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForCompletions(int completions) {
    if (completions == 0) return Colors.grey[200]!;

    final intensity = completions / maxCompletions;
    if (intensity < 0.25) return Colors.blue[100]!;
    if (intensity < 0.5) return Colors.blue[300]!;
    if (intensity < 0.75) return Colors.blue[500]!;
    return Colors.blue[700]!;
  }

  void _showDayDetails(BuildContext context, DateTime date, int completions) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(date_utils.DateUtils.formatDateForApi(date)),
            content: Text('$completions habits completed'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }
}