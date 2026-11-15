import 'dart:async';
import 'package:intl/intl.dart';
import '../../domain/entities/ble_device_entity.dart';
import '../../domain/entities/clock_status.dart';
import '../../domain/interfaces/i_clock_repository.dart';

/// Мок-реалізація IClockRepository (Infrastructure Layer) для автономного тестування та демо-режиму
class MockClockRepository implements IClockRepository {
  bool _isConnected = false;
  BleDeviceEntity? _connectedDevice;
  final ClockStatus _status = ClockStatus();

  final StreamController<ClockStatus> _statusController = StreamController<ClockStatus>.broadcast();
  final StreamController<List<BleDeviceEntity>> _scanResultsController = StreamController<List<BleDeviceEntity>>.broadcast();

  Timer? _mockTimer;

  MockClockRepository() {
    _startSimulatedUpdates();
  }

  void _startSimulatedUpdates() {
    _mockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      _status.time = DateFormat('HH:mm:ss').format(now);
      _status.date = DateFormat('dd.MM.yyyy').format(now);
      final temp = 24.0 + (now.second % 5) * 0.2;
      _status.temperature = "${temp.toStringAsFixed(1)}°C";
      _statusController.add(_status.copy());
    });
  }

  @override
  bool get isConnected => _isConnected;

  @override
  ClockStatus get currentStatus => _status;

  @override
  Stream<ClockStatus> get statusStream => _statusController.stream;

  @override
  Stream<List<BleDeviceEntity>> get scanResultsStream => _scanResultsController.stream;

  @override
  BleDeviceEntity? get connectedDevice => _connectedDevice;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  void startScan({void Function(List<BleDeviceEntity> results)? onResults}) {
    final mockDevices = const [
      BleDeviceEntity(id: "ESP32_DEMO_01", name: "ESP32-C3 Clock", rssi: -45),
      BleDeviceEntity(id: "ESP32_DEMO_02", name: "ESP32 Desk Sensor", rssi: -62),
    ];
    _scanResultsController.add(mockDevices);
    onResults?.call(mockDevices);
  }

  @override
  void stopScan() {}

  @override
  Future<bool> connect(BleDeviceEntity device, {void Function()? onDisconnect}) async {
    _isConnected = true;
    _connectedDevice = device;
    _statusController.add(_status.copy());
    return true;
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    _connectedDevice = null;
    _statusController.add(_status.copy());
  }

  @override
  void sendCommand(String command) {
    if (command.startsWith("DISPLAY")) {
      _status.mode = command.substring(7);
      _status.autoMode = "OFF";
    } else if (command == "AUTOMODE") {
      _status.autoMode = _status.autoMode == "ON" ? "OFF" : "ON";
    } else if (command == "ALARM=OFF") {
      _status.alarm = "OFF";
      _status.alarmState = "OFF";
    } else if (command.startsWith("ALARM=")) {
      _status.alarm = command.substring(6);
      _status.alarmState = "WAITING";
    } else if (command == "ALARMSTOP") {
      _status.alarmState = "WAITING";
    } else if (command.startsWith("TIMER=")) {
      _status.timer = command.substring(6);
    } else if (command == "TIMERSTART") {
      _status.timerState = "RUNNING";
    } else if (command == "TIMERSTOP") {
      _status.timerState = "STOPPED";
    } else if (command == "TIMERRESET") {
      _status.timer = "0s";
      _status.timerState = "STOPPED";
    } else if (command == "STOPWATCHSTART") {
      _status.stopwatchState = "RUNNING";
    } else if (command == "STOPWATCHSTOP") {
      _status.stopwatchState = "STOPPED";
    } else if (command == "STOPWATCHRESET") {
      _status.stopwatch = "0s";
      _status.stopwatchState = "STOPPED";
    }
    _statusController.add(_status.copy());
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _statusController.close();
    _scanResultsController.close();
  }
}
