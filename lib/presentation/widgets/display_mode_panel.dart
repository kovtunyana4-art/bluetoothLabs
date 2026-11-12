import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/clock_notifier.dart';

class DisplayModePanel extends StatelessWidget {
  const DisplayModePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClockNotifier>();
    final status = notifier.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Режим дисплея", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ModeButton(
              label: "Час",
              icon: Icons.access_time,
              command: "DISPLAYTIME",
              isActive: status.mode == "TIME" && status.autoMode == "OFF",
            ),
            _ModeButton(
              label: "Температура",
              icon: Icons.thermostat,
              command: "DISPLAYTEMP",
              isActive: status.mode == "TEMP" && status.autoMode == "OFF",
            ),
            _ModeButton(
              label: "Дата",
              icon: Icons.calendar_today,
              command: "DISPLAYDATE",
              isActive: status.mode == "DATE" && status.autoMode == "OFF",
            ),
            _ModeButton(
              label: "Таймер",
              icon: Icons.hourglass_bottom,
              command: "DISPLAYTIMER",
              isActive: status.mode == "TIMER" && status.autoMode == "OFF",
            ),
            _ModeButton(
              label: "Секундомір",
              icon: Icons.timer,
              command: "DISPLAYSTOPWATCH",
              isActive: status.mode == "STOPWATCH" && status.autoMode == "OFF",
            ),
            _ModeButton(
              label: "Авто",
              icon: Icons.autorenew,
              command: "AUTOMODE",
              isActive: status.autoMode == "ON",
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String command;
  final bool isActive;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.command,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blueAccent.withValues(alpha: 0.3) : null,
        minimumSize: const Size(140, 45),
      ),
      onPressed: () => context.read<ClockNotifier>().sendCommand(command),
      icon: Icon(icon, size: 18, color: isActive ? Colors.blueAccent : null),
      label: Text(label, style: TextStyle(color: isActive ? Colors.blueAccent : null)),
    );
  }
}
