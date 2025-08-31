
// lib/widgets/daily_checkin_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';

class DailyCheckinWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        if (habitProvider.habits.isEmpty) {
          return Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.track_changes,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 12),
                Text(
                  'No habits to check in',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add some habits to start tracking!',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final today = DateTime.now();
        final completedToday = habitProvider.getCompletionsForDate(today);
        final totalHabits = habitProvider.habits.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress summary
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.today,
                    color: Colors.blue[700],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$completedToday of $totalHabits habits completed',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Circular progress indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          value: totalHabits > 0 ? completedToday / totalHabits : 0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          strokeWidth: 6,
                        ),
                      ),
                      Text(
                        '${((totalHabits > 0 ? completedToday / totalHabits : 0) * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Quick checkin list
            Text(
              'Quick Check-in',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),

            ...habitProvider.habits.take(5).map((habit) {
              final isCompleted = _isHabitCompletedToday(habitProvider, habit, today);

              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (habit.id == null) return;

                        try {
                          if (isCompleted) {
                            await habitProvider.markHabitIncomplete(habit.id!, today);
                          } else {
                            await habitProvider.markHabitComplete(habit.id!, today);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating habit'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted ? habit.colorValue : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? habit.colorValue : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? Icon(Icons.check, color: Colors.white, size: 14)
                            : null,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey[600] : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            if (habitProvider.habits.length > 5) ...[
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Navigate to habits tab
                  DefaultTabController.of(context)?.animateTo(1);
                },
                child: Text('View all habits'),
              ),
            ],
          ],
        );
      },
    );
  }

  bool _isHabitCompletedToday(HabitProvider habitProvider, Habit habit, DateTime date) {
    // Simplified check - in a real app, you'd track individual habit completions
    return habitProvider.getCompletionsForDate(date) > 0;
  }
}
