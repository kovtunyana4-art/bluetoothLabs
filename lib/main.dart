import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'clock_notifier.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ClockNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32-C3 Mini Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClockNotifier>();

    if (!notifier.isConnected && !notifier.showMockDashboard) {
      return const DeviceScannerView();
    }

    return const ClockDashboardView();
  }
}

class DeviceScannerView extends StatelessWidget {
  const DeviceScannerView({super.key});

  void _handleConnect(BuildContext context, BluetoothDevice device) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    context.read<ClockNotifier>().connectToDevice(
      device,
      onMessage: (message) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClockNotifier>();
    final scanResults = notifier.scanResults;
    final isScanning = notifier.isScanning;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Виберіть пристрій (BLE)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => context.read<ClockNotifier>().setShowMockDashboard(true),
            tooltip: "Демо-режим",
          ),
          if (isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                context.read<ClockNotifier>().startScan(
                  onMessage: (message) {
                    scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
                  },
                );
              },
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: scanResults.length,
        itemBuilder: (itemContext, index) {
          final result = scanResults[index];
          final device = result.device;
          String deviceName = device.platformName.isNotEmpty ? device.platformName : "Невідомий BLE пристрій";
          if (deviceName == "Невідомий BLE пристрій" && result.advertisementData.advName.isNotEmpty) {
            deviceName = result.advertisementData.advName;
          }

          return ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(deviceName),
            subtitle: Text(device.remoteId.toString()),
            trailing: ElevatedButton(
              child: const Text("Підключити"),
              onPressed: () => _handleConnect(itemContext, device),
            ),
          );
        },
      ),
    );
  }
}

class ClockDashboardView extends StatelessWidget {
  const ClockDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClockNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const ClockAppBarTitle(),
        actions: [
          IconButton(
            icon: Icon(notifier.showMockDashboard ? Icons.close : Icons.bluetooth_disabled),
            onPressed: () async {
              final clockNotifier = context.read<ClockNotifier>();
              if (clockNotifier.showMockDashboard) {
                clockNotifier.setShowMockDashboard(false);
                clockNotifier.startScan();
              } else {
                await clockNotifier.disconnect();
              }
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClockStatusCard(),
            ActiveAlertBanner(),
            SizedBox(height: 20),
            DisplayModePanel(),
            SizedBox(height: 20),
            ControlPanel(),
            SizedBox(height: 20),
            TestPanel(),
          ],
        ),
      ),
    );
  }
}

class ClockAppBarTitle extends StatelessWidget {
  const ClockAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClockNotifier>();
    if (notifier.showMockDashboard) {
      return Text("Панель керування (Демо: ${notifier.status.time})");
    }
    return Text("ESP32-C3 Годинник [${notifier.status.mode}]");
  }
}

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
        String datetimeCmd = "DATETIME=${pickedDate.day.toString().padLeft(2, '0')}.${pickedDate.month.toString().padLeft(2, '0')}.${pickedDate.year} ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00";
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
                String hour = picked.hour.toString().padLeft(2, '0');
                String minute = picked.minute.toString().padLeft(2, '0');
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
              String mm = minutesController.text.padLeft(2, '0');
              String ss = secondsController.text.padLeft(2, '0');
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
            children: [
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
