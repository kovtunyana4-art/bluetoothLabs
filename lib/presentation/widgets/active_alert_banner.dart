import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/clock_notifier.dart';

class ActiveAlertBanner extends StatelessWidget {
  const ActiveAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClockNotifier>();
    final status = notifier.status;
    final isAlarmTriggered = status.alarmState == "TRIGGERED";
    final isTimerFinished = status.timerState == "FINISHED";

    if (!isAlarmTriggered && !isTimerFinished) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (isAlarmTriggered) ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
            ),
            icon: const Icon(Icons.alarm_off, size: 32),
            label: const Text(
              "ЗУПИНИТИ БУДИЛЬНИК",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            onPressed: () => context.read<ClockNotifier>().sendCommand("ALARMSTOP"),
          ),
        ],
        if (isTimerFinished) ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
            ),
            icon: const Icon(Icons.timer_off, size: 32),
            label: const Text(
              "ЗУПИНИТИ ТАЙМЕР",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            onPressed: () => context.read<ClockNotifier>().sendCommand("TIMERRESET"),
          ),
        ],
      ],
    );
  }
}
