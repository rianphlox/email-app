/// Utility class for formatting dates in various contexts
class DateFormatUtils {
  /// Formats a date relative to now in Gmail style
  /// - Shows time (e.g., "4:26 PM") for emails from today
  /// - Shows date (e.g., "Nov 14") for emails from other days
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);

    if (isToday) {
      // Show time for emails from today (Gmail style)
      return _formatTime(date);
    } else if (date.year == now.year) {
      // Show month and day for emails from this year (e.g., "Nov 14")
      return _formatMonthDay(date);
    } else {
      // Show full year for older emails (e.g., "Dec 2023")
      return _formatMonthYear(date);
    }
  }

  /// Formats a full date for detailed views
  static String formatFullDate(DateTime date) {
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final isYesterday = _isSameDay(date, now.subtract(const Duration(days: 1)));
    final isThisWeek = now.difference(date).inDays < 7;
    final isThisYear = date.year == now.year;

    if (isToday) {
      return 'Today, ${_formatTime(date)}';
    } else if (isYesterday) {
      return 'Yesterday, ${_formatTime(date)}';
    } else if (isThisWeek) {
      return '${_formatWeekday(date)}, ${_formatTime(date)}';
    } else if (isThisYear) {
      return '${_formatMonthDay(date)}, ${_formatTime(date)}';
    } else {
      return '${_formatDate(date)}, ${_formatTime(date)}';
    }
  }

  /// Formats time in 12-hour format (e.g., "2:30 PM")
  static String formatTime(DateTime date) {
    return _formatTime(date);
  }

  /// Formats date in MM/DD/YYYY format
  static String formatDate(DateTime date) {
    return _formatDate(date);
  }

  /// Checks if two dates are on the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Formats time in 12-hour format
  static String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');

    return '$displayHour:$displayMinute $period';
  }

  /// Formats date as MM/DD/YYYY
  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  /// Formats month and day (e.g., "Jan 15")
  static String _formatMonthDay(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Formats month and year (e.g., "Dec 2023")
  static String _formatMonthYear(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Formats weekday (e.g., "Monday")
  static String _formatWeekday(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[date.weekday - 1];
  }

  /// Formats a date range (e.g., "Jan 15 - Jan 20, 2024")
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    if (_isSameDay(startDate, endDate)) {
      return formatFullDate(startDate);
    }

    final startYear = startDate.year;
    final endYear = endDate.year;
    final startMonth = startDate.month;
    final endMonth = endDate.month;

    if (startYear == endYear) {
      if (startMonth == endMonth) {
        // Same month: "Jan 15 - 20, 2024"
        return '${_formatMonthDay(startDate)} - ${endDate.day}, $endYear';
      } else {
        // Same year, different months: "Jan 15 - Feb 20, 2024"
        return '${_formatMonthDay(startDate)} - ${_formatMonthDay(endDate)}, $endYear';
      }
    } else {
      // Different years: "Dec 25, 2023 - Jan 5, 2024"
      return '${_formatMonthDay(startDate)}, $startYear - ${_formatMonthDay(endDate)}, $endYear';
    }
  }

  /// Formats duration (e.g., "2 hours ago", "3 days ago")
  static String formatDurationAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  /// Formats timestamp for sorting (YYYYMMDDHHMMSS)
  static String formatTimestamp(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '$year$month$day$hour$minute$second';
  }
}