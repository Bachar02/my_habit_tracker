
// lib/widgets/streak_counter.dart
import 'package:flutter/material.dart';

class StreakCounter extends StatelessWidget {
  final int streak;
  final bool showIcon;

  const StreakCounter({
    Key? key,
    required this.streak,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStreakColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStreakColor().withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: _getStreakColor(),
            ),
            SizedBox(width: 4),
          ],
          Text(
            '$streak day${streak != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getStreakColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStreakColor() {
    if (streak == 0) return Colors.grey;
    if (streak < 7) return Colors.orange;
    if (streak < 30) return Colors.blue;
    return Colors.green;
  }
}