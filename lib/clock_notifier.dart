import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'bluetooth_manager.dart';

class ClockNotifier extends ChangeNotifier {
  final BluetoothManager _btManager;

  bool _showMockDashboard = true;
  bool _isScanning = false;
  bool _isDisposed = false;
  List<ScanResult> _scanResults = [];

  Timer? _mockTimer;
  Timer? _pollTimer;
  Timer? _scanTimer;
  StreamSubscription<ClockStatus>? _statusSubscription;

  ClockNotifier({BluetoothManager? btManager})
      : _btManager = btManager ?? BluetoothManager() {
    _startMockUpdates();
    _startPolling();
    _listenToBtStatus();
    startScan();
  }

  bool get showMockDashboard => _showMockDashboard;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => _scanResults;
  bool get isConnected => _btManager.isConnected;
  ClockStatus get status => _btManager.currentStatus;
  BluetoothDevice? get connectedDevice => _btManager.connectedDevice;

  String get connectedDeviceName {
    if (_btManager.connectedDevice == null) return "";
    final name = _btManager.connectedDevice!.platformName;
    return name.isNotEmpty ? name : "BLE пристрій";
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void _listenToBtStatus() {
    _statusSubscription = _btManager.statusStream.listen((_) {
      notifyListeners();
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_btManager.isConnected && !_showMockDashboard) {
        _btManager.sendCommand("STATUS");
      }
    });
  }

  void _startMockUpdates() {
    _mockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_showMockDashboard && !_btManager.isConnected) {
        DateTime now = DateTime.now();
        _btManager.currentStatus.time = DateFormat('HH:mm:ss').format(now);
        _btManager.currentStatus.date = DateFormat('dd.MM.yyyy').format(now);
        double temp = 24.0 + (now.second % 5) * 0.2;
        _btManager.currentStatus.temperature = "${temp.toStringAsFixed(1)}°C";
        notifyListeners();
      }
    });
  }

  Future<void> startScan({void Function(String message)? onMessage}) async {
    _scanResults = [];
    _isScanning = true;
    notifyListeners();

    try {
      bool permissionsGranted = await _btManager.requestPermissions();
      if (!permissionsGranted) {
        onMessage?.call("Надайте дозволи для Bluetooth/Локації");
      }

      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        onMessage?.call("Будь ласка, увімкніть Bluetooth");
        _isScanning = false;
        notifyListeners();
        return;
      }

      _btManager.startScan((results) {
        _scanResults = results;
        notifyListeners();
      });

      _scanTimer?.cancel();
      _scanTimer = Timer(const Duration(seconds: 5), () {
        _isScanning = false;
        notifyListeners();
      });
    } catch (e) {
      onMessage?.call("Помилка сканування: $e");
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> connectToDevice(
    BluetoothDevice device, {
    void Function(String message)? onMessage,
  }) async {
    _btManager.stopScan();
    _showMockDashboard = false;
    notifyListeners();

    String devName = device.platformName.isNotEmpty ? device.platformName : "Невідомий пристрій";
    onMessage?.call("Підключення до $devName...");

    bool success = await _btManager.connect(device, () {
      notifyListeners();
      onMessage?.call("Пристрій відключено");
      startScan(onMessage: onMessage);
    });

    if (success) {
      DateTime now = DateTime.now();
      String datetimeCmd = "DATETIME=${DateFormat('dd.MM.yyyy HH:mm:ss').format(now)}";
      _btManager.sendCommand(datetimeCmd);
    } else {
      onMessage?.call("Не вдалося підключитися (не знайдено сервісу/характеристик)");
    }

    notifyListeners();
    return success;
  }

  Future<void> disconnect() async {
    await _btManager.disconnect();
    notifyListeners();
    startScan();
  }

  void setShowMockDashboard(bool value) {
    _showMockDashboard = value;
    notifyListeners();
  }

  void sendCommand(String command) {
    if (_btManager.isConnected) {
      _btManager.sendCommand(command);
    } else if (_showMockDashboard) {
      if (command.startsWith("DISPLAY")) {
        _btManager.currentStatus.mode = command.substring(7);
        _btManager.currentStatus.autoMode = "OFF";
      } else if (command == "AUTOMODE") {
        _btManager.currentStatus.autoMode = _btManager.currentStatus.autoMode == "ON" ? "OFF" : "ON";
      } else if (command == "ALARM=OFF") {
        _btManager.currentStatus.alarm = "OFF";
        _btManager.currentStatus.alarmState = "OFF";
      } else if (command.startsWith("ALARM=")) {
        _btManager.currentStatus.alarm = command.substring(6);
        _btManager.currentStatus.alarmState = "WAITING";
      } else if (command == "ALARMSTOP") {
        _btManager.currentStatus.alarmState = "WAITING";
      } else if (command.startsWith("TIMER=")) {
        _btManager.currentStatus.timer = command.substring(6);
      } else if (command == "TIMERSTART") {
        _btManager.currentStatus.timerState = "RUNNING";
      } else if (command == "TIMERSTOP") {
        _btManager.currentStatus.timerState = "STOPPED";
      } else if (command == "TIMERRESET") {
        _btManager.currentStatus.timer = "0s";
        _btManager.currentStatus.timerState = "STOPPED";
      } else if (command == "STOPWATCHSTART") {
        _btManager.currentStatus.stopwatchState = "RUNNING";
      } else if (command == "STOPWATCHSTOP") {
        _btManager.currentStatus.stopwatchState = "STOPPED";
      } else if (command == "STOPWATCHRESET") {
        _btManager.currentStatus.stopwatch = "0s";
        _btManager.currentStatus.stopwatchState = "STOPPED";
      }
      notifyListeners();
    }
  }

  void syncTime() {
    DateTime now = DateTime.now();
    String datetimeCmd = "DATETIME=${DateFormat('dd.MM.yyyy HH:mm:ss').format(now)}";
    sendCommand(datetimeCmd);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mockTimer?.cancel();
    _mockTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _scanTimer?.cancel();
    _scanTimer = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _btManager.stopScan();
    super.dispose();
  }
}
