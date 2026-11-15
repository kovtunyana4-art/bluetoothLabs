import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/clock_notifier.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  void _pickDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && context.mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null && context.mounted) {
        final datetimeCmd = "DATETIME=${pickedDate.day.toString().padLeft(2, '0')}.${pickedDate.month.toString().padLeft(2, '0')}.${pickedDate.year} ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00";
        context.read<ClockNotifier>().sendCommand(datetimeCmd);
      }
    }
  }

  void _pickAlarm(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Будильник"),
        content: const Text("Бажаєте встановити новий час чи вимкнути будильник повністю?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ClockNotifier>().sendCommand("ALARM=OFF");
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("ВИМКНУТИ"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null && context.mounted) {
                final hour = picked.hour.toString().padLeft(2, '0');
                final minute = picked.minute.toString().padLeft(2, '0');
                context.read<ClockNotifier>().sendCommand("ALARM=$hour:$minute");
              }
            },
            child: const Text("ВСТАНОВИТИ ЧАС"),
          ),
        ],
      ),
    );
  }

  void _pickTimer(BuildContext context) async {
    final minutesController = TextEditingController(text: "01");
    final secondsController = TextEditingController(text: "00");

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Встановити таймер"),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextField(
                controller: minutesController,
                decoration: const InputDecoration(labelText: "Хв"),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            const Text(":", style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: secondsController,
                decoration: const InputDecoration(labelText: "Сек"),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Скасувати"),
          ),
          ElevatedButton(
            onPressed: () {
              final mm = minutesController.text.padLeft(2, '0');
              final ss = secondsController.text.padLeft(2, '0');
              final clockNotifier = context.read<ClockNotifier>();
              clockNotifier.sendCommand("TIMER=$mm:$ss");
              clockNotifier.sendCommand("TIMERSTART");
              Navigator.pop(dialogContext);
            },
            child: const Text("Старт"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Керування", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // Time & Date
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionButton(
                  label: "Синхронізувати час",
                  icon: Icons.sync,
                  onPressed: () => context.read<ClockNotifier>().syncTime(),
                ),
                _ActionButton(
                  label: "Встановити час/дату",
                  icon: Icons.edit_calendar,
                  onPressed: () => _pickDateTime(context),
                ),
              ],
            ),
          ),
        ),

        // Alarm
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionButton(
                  label: "Новий будильник",
                  icon: Icons.alarm_add,
                  onPressed: () => _pickAlarm(context),
                ),
                _ActionButton(
                  label: "Вимкнути будильник",
                  icon: Icons.alarm_off,
                  onPressed: () => context.read<ClockNotifier>().sendCommand("ALARM=OFF"),
                ),
              ],
            ),
          ),
        ),

        // Timer
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionButton(
                  label: "Налаштувати таймер",
                  icon: Icons.hourglass_top,
                  onPressed: () => _pickTimer(context),
                ),
                _ActionButton(
                  label: "Старт",
                  icon: Icons.play_arrow,
                  onPressed: () => context.read<ClockNotifier>().sendCommand("TIMERSTART"),
                ),
                _ActionButton(
                  label: "Стоп",
                  icon: Icons.pause,
                  onPressed: () => context.read<ClockNotifier>().sendCommand("TIMERSTOP"),
                ),
                _ActionButton(
                  label: "Скинути",
                  icon: Icons.refresh,
                  onPressed: () => context.read<ClockNotifier>().sendCommand("TIMERRESET"),
                ),
              ],
            ),
          ),
        ),

        // Stopwatch
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionButton(
                  label: "Старт секундомір",
                  icon: Icons.play_arrow,
                  onPressed: () => context.read<ClockNotifier>().sendCommand("STOPWATCHSTART"),
                ),
                _ActionButton(
                  label: "Стоп",
                  icon: Icons.pause,
                  onPressed: () => context.read<ClockNotifier>().sendCommand("STOPWATCHSTOP"),
                ),
                _ActionButton(
                  label: "Скинути",
                  icon: Icons.refresh,
                  onPressed: () => context.read<ClockNotifier>().sendCommand("STOPWATCHRESET"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
