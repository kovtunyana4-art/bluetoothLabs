import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/ble_device_entity.dart';
import '../notifiers/clock_notifier.dart';

class DeviceScannerView extends StatelessWidget {
  const DeviceScannerView({super.key});

  void _handleConnect(BuildContext context, BleDeviceEntity device) {
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
          final device = scanResults[index];
          return ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(device.displayName),
            subtitle: Text(device.id),
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
