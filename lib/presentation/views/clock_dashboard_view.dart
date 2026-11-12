import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/clock_notifier.dart';
import '../widgets/clock_status_card.dart';
import '../widgets/active_alert_banner.dart';
import '../widgets/display_mode_panel.dart';
import '../widgets/control_panel.dart';
import '../widgets/test_panel.dart';

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
