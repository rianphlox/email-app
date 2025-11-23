import 'package:flutter/material.dart';

class SnoozeDialog extends StatefulWidget {
  const SnoozeDialog({super.key});

  @override
  State<SnoozeDialog> createState() => _SnoozeDialogState();
}

class _SnoozeDialogState extends State<SnoozeDialog> {
  DateTime? selectedDateTime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Snooze Email'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'When should this email reappear in your inbox?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Quick snooze options
          _buildQuickSnoozeOption('Later today', _getTimeToday(18, 0)),
          _buildQuickSnoozeOption('Tomorrow', _getTomorrow(8, 0)),
          _buildQuickSnoozeOption('This weekend', _getWeekend()),
          _buildQuickSnoozeOption('Next week', _getNextWeek()),

          const Divider(),

          // Custom date/time picker
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Pick date & time'),
            subtitle: selectedDateTime != null
                ? Text(_formatDateTime(selectedDateTime!))
                : null,
            onTap: _pickCustomDateTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedDateTime != null
              ? () => Navigator.of(context).pop(selectedDateTime)
              : null,
          child: const Text('Snooze'),
        ),
      ],
    );
  }

  Widget _buildQuickSnoozeOption(String title, DateTime dateTime) {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text(title),
      subtitle: Text(_formatDateTime(dateTime)),
      onTap: () {
        setState(() {
          selectedDateTime = dateTime;
        });
      },
      selected: selectedDateTime == dateTime,
    );
  }

  DateTime _getTimeToday(int hour, int minute) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, hour, minute);

    // If the time has passed today, make it tomorrow
    if (today.isBefore(now)) {
      return today.add(const Duration(days: 1));
    }
    return today;
  }

  DateTime _getTomorrow(int hour, int minute) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, hour, minute);
    return tomorrow;
  }

  DateTime _getWeekend() {
    final now = DateTime.now();
    final daysUntilSaturday = (6 - now.weekday) % 7;
    final saturday = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSaturday,
      9, // 9 AM Saturday
      0,
    );

    // If it's already Saturday or Sunday, next weekend
    if (daysUntilSaturday == 0 && now.hour >= 9) {
      return saturday.add(const Duration(days: 7));
    }

    return saturday;
  }

  DateTime _getNextWeek() {
    final now = DateTime.now();
    final daysUntilNextMonday = (8 - now.weekday) % 7;
    final nextMonday = DateTime(
      now.year,
      now.month,
      now.day + daysUntilNextMonday,
      8, // 8 AM next Monday
      0,
    );
    return nextMonday;
  }

  Future<void> _pickCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      if (time != null && mounted) {
        setState(() {
          selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return 'Today at $timeStr';
    } else if (messageDate == tomorrow) {
      return 'Tomorrow at $timeStr';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day} at $timeStr';
    }
  }
}

/// Utility function to show snooze dialog
Future<DateTime?> showSnoozeDialog(BuildContext context) async {
  return showDialog<DateTime?>(
    context: context,
    builder: (context) => const SnoozeDialog(),
  );
}