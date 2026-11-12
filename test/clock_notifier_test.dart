import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bluetooth/clock_notifier.dart';
import 'package:bluetooth/main.dart';

void main() {
  group('ClockNotifier Tests', () {
    test('Initializes with default values and can notify listeners', () {
      final notifier = ClockNotifier();
      expect(notifier.showMockDashboard, isTrue);
      expect(notifier.isConnected, isFalse);

      bool notified = false;
      notifier.addListener(() {
        notified = true;
      });

      notifier.setShowMockDashboard(false);
      expect(notified, isTrue);
      expect(notifier.showMockDashboard, isFalse);

      notifier.dispose();
    });

    test('sendCommand updates mock status and calls notifyListeners', () {
      final notifier = ClockNotifier();
      bool notified = false;
      notifier.addListener(() {
        notified = true;
      });

      notifier.sendCommand('DISPLAYTEMP');
      expect(notified, isTrue);
      expect(notifier.status.mode, 'TEMP');

      notifier.sendCommand('AUTOMODE');
      expect(notifier.status.autoMode, 'ON');

      notifier.sendCommand('ALARM=08:30');
      expect(notifier.status.alarm, '08:30');
      expect(notifier.status.alarmState, 'WAITING');

      notifier.dispose();
    });

    test('dispose cleans up timers safely without throw', () {
      final notifier = ClockNotifier();
      expect(() => notifier.dispose(), returnsNormally);
    });
  });

  group('Provider & Widget Tree Tests (No Prop Drilling)', () {
    testWidgets('Renders ClockDashboardView with context.watch in multiple widgets', (tester) async {
      final notifier = ClockNotifier();
      notifier.status.time = '12:34:56';
      notifier.status.temperature = '25.0°C';

      await tester.pumpWidget(
        ChangeNotifierProvider<ClockNotifier>.value(
          value: notifier,
          child: const MyApp(),
        ),
      );

      // Verify ClockAppBarTitle watched the notifier
      expect(find.byType(ClockAppBarTitle), findsOneWidget);
      expect(find.textContaining('Панель керування (Демо: 12:34:56)'), findsOneWidget);

      // Verify ClockStatusCard watched the notifier without prop drilling
      expect(find.byType(ClockStatusCard), findsOneWidget);
      expect(find.text('12:34:56'), findsOneWidget);
      expect(find.text('25.0°C'), findsOneWidget);

      // Verify DisplayModePanel watched the notifier
      expect(find.byType(DisplayModePanel), findsOneWidget);

      // Trigger an event handler using context.read
      final timeButton = find.widgetWithText(ElevatedButton, 'Температура');
      expect(timeButton, findsOneWidget);
      await tester.tap(timeButton);
      await tester.pump();

      expect(notifier.status.mode, 'TEMP');

      notifier.dispose();
    });

    testWidgets('Switches to DeviceScannerView when not connected and demo disabled', (tester) async {
      final notifier = ClockNotifier();
      notifier.setShowMockDashboard(false);

      await tester.pumpWidget(
        ChangeNotifierProvider<ClockNotifier>.value(
          value: notifier,
          child: const MyApp(),
        ),
      );

      expect(find.byType(DeviceScannerView), findsOneWidget);
      expect(find.text('Виберіть пристрій (BLE)'), findsOneWidget);

      // Tap demo button to switch back using context.read
      final demoIcon = find.byIcon(Icons.dashboard);
      expect(demoIcon, findsOneWidget);
      await tester.tap(demoIcon);
      await tester.pump();

      expect(notifier.showMockDashboard, isTrue);
      expect(find.byType(ClockDashboardView), findsOneWidget);

      notifier.dispose();
    });
  });
}
