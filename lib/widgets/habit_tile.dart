// lib/widgets/habit_tile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/streak_counter.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onDelete;

  const HabitTile({
    Key? key,
    required this.habit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final isCompleted = _isHabitCompletedToday(habitProvider, today);
        final streak = habitProvider.getStreakForHabit(habit.id ?? 0);

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Habit color indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: habit.colorValue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.track_changes,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                SizedBox(width: 16),

                // Habit details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (habit.description != null) ...[
                        SizedBox(height: 4),
                        Text(
                          habit.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      StreakCounter(streak: streak),
                    ],
                  ),
                ),

                // Today's completion checkbox
                Column(
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted ? habit.colorValue : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? habit.colorValue : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                // More options
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    switch (value) {
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isHabitCompletedToday(HabitProvider habitProvider, DateTime date) {
    // This is a simplified check - you might want to implement a more sophisticated
    // method to track individual habit completions per date
    return habitProvider.getCompletionsForDate(date) > 0;
  }
}
