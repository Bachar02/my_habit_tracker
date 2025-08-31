
// lib/utils/date_utils.dart
class DateUtils {
  /// Format date as YYYY-MM-DD
  static String formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get the start of the week (Sunday)
  static DateTime getStartOfWeek(DateTime date) {
    final daysSinceStartOfWeek = date.weekday % 7;
    return date.subtract(Duration(days: daysSinceStartOfWeek));
  }

  /// Get all dates in a year
  static List<DateTime> getAllDatesInYear(int year) {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    final dates = <DateTime>[];

    for (var date = startDate;
    date.isBefore(endDate) || DateUtils.isSameDay(date, endDate);
    date = date.add(Duration(days: 1))) {
      dates.add(date);
    }

    return dates;
  }

  /// Get the number of weeks needed to display a year
  static int getWeeksInYear(int year) {
    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);
    final totalDays = lastDay.difference(firstDay).inDays + 1;
    return ((totalDays + firstDay.weekday - 1) / 7).ceil();
  }

  /// Format date for display (e.g., "Mon, Jan 15")
  static String formatDateForDisplay(DateTime date) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return '${dayNames[date.weekday % 7]}, ${monthNames[date.month - 1]} ${date.day}';
  }

  /// Get relative date string (Today, Yesterday, etc.)
  static String getRelativeDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == -1) return 'Tomorrow';
    if (difference > 1 && difference <= 7) return '${difference} days ago';
    if (difference < -1 && difference >= -7) return 'In ${-difference} days';

    return formatDateForDisplay(date);
  }

  /// Get the week number of the year
  static int getWeekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysSinceStartOfYear = date.difference(startOfYear).inDays;
    return ((daysSinceStartOfYear + startOfYear.weekday - 1) / 7).ceil();
  }
}