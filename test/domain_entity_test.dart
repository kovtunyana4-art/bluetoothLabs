import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth/domain/entities/clock_status.dart';
import 'package:bluetooth/domain/entities/ble_device_entity.dart';

void main() {
  group('Domain Entities Tests', () {
    test('ClockStatus initializes with default values and clones correctly', () {
      final status = ClockStatus();
      expect(status.time, equals('--:--:--'));
      expect(status.mode, equals('TIME'));
      expect(status.alarm, equals('OFF'));
      expect(status.isAlarmTriggered, isFalse);

      final cloned = status.copy();
      expect(cloned.time, equals(status.time));
      expect(cloned.mode, equals(status.mode));
    });

    test('ClockStatus correctly updates from BLE serial protocol lines', () {
      final status = ClockStatus();
      status.updateFromLine('TIME=14:30:00');
      status.updateFromLine('DATE=14.11.2026');
      status.updateFromLine('TEMP=24.5C');
      status.updateFromLine('ALARM=07:00');
      status.updateFromLine('ALARM:TRIGGERED');

      expect(status.time, equals('14:30:00'));
      expect(status.date, equals('14.11.2026'));
      expect(status.temperature, equals('24.5°C'));
      expect(status.alarm, equals('07:00'));
      expect(status.isAlarmEnabled, isTrue);
      expect(status.isAlarmTriggered, isTrue);
    });

    test('BleDeviceEntity provides friendly display name and equality check', () {
      const dev1 = BleDeviceEntity(id: 'AA:BB:CC:DD:EE:01', name: 'SmartClock BLE', rssi: -65);
      const dev2 = BleDeviceEntity(id: 'AA:BB:CC:DD:EE:01', name: 'SmartClock BLE');
      const nameless = BleDeviceEntity(id: 'AA:BB:CC:DD:EE:02', name: '');

      expect(dev1, equals(dev2));
      expect(dev1.displayName, equals('SmartClock BLE'));
      expect(nameless.displayName, equals('Невідомий BLE пристрій'));
    });
  });
}
