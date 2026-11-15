import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/clock_notifier.dart';

class ClockStatusCard extends StatelessWidget {
  const ClockStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClockNotifier>();
    final status = notifier.status;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          status.time,
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      Text(status.date, style: const TextStyle(fontSize: 20, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          status.temperature,
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            status.autoMode == "ON" ? "АВТО: УВІМК" : "РЕЖИМ: ${status.mode}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusItem(label: "Будильник", value: status.alarm, icon: Icons.alarm, state: status.alarmState),
                _StatusItem(label: "Таймер", value: status.formattedTimer, icon: Icons.hourglass_empty, state: status.timerState),
                _StatusItem(label: "Секундомір", value: status.formattedStopwatch, icon: Icons.timer, state: status.stopwatchState),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? state;

  const _StatusItem({
    required this.label,
    required this.value,
    required this.icon,
    this.state,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = Colors.grey;
    if (state == "TRIGGERED" || state == "RUNNING" || state == "FINISHED") {
      iconColor = Colors.orangeAccent;
    }

    return Column(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        if (state != null && state != "WAITING" && state != "STOPPED" && state != "OFF")
          Text(state!, style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
