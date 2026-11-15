import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/clock_notifier.dart';
import 'device_scanner_view.dart';
import 'clock_dashboard_view.dart';

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
