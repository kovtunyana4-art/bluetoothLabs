import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/clock_notifier.dart';

class TestPanel extends StatelessWidget {
  const TestPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Тестування компонентів", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              _TestButton(label: "Усе разом", command: "CHECK_ALL"),
              _TestButton(label: "Дисплей", command: "CHECK_DISPLAY"),
              _TestButton(label: "NeoPixel", command: "CHECK_NEOPIXEL"),
              _TestButton(label: "Бузер", command: "CHECK_BUZZER"),
            ],
          ),
        ),
      ],
    );
  }
}

class _TestButton extends StatelessWidget {
  final String label;
  final String command;

  const _TestButton({
    required this.label,
    required this.command,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: () => context.read<ClockNotifier>().sendCommand(command),
        child: Text(label),
      ),
    );
  }
}
