import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ClockStatus {
  String time = "--:--:--";
  String date = "--.--.----";
  String temperature = "--.-°C";
  String mode = "TIME";
  String autoMode = "OFF";
  String alarm = "OFF";
  String alarmState = "WAITING";
  String timer = "0s";
  String timerState = "STOPPED";
  String stopwatch = "0s";
  String stopwatchState = "STOPPED";

  ClockStatus();

  ClockStatus copy() {
    ClockStatus copy = ClockStatus();
    copy.time = time;
    copy.date = date;
    copy.temperature = temperature;
    copy.mode = mode;
    copy.autoMode = autoMode;
    copy.alarm = alarm;
    copy.alarmState = alarmState;
    copy.timer = timer;
    copy.timerState = timerState;
    copy.stopwatch = stopwatch;
    copy.stopwatchState = stopwatchState;
    return copy;
  }

  String get formattedTimer {
    String secStr = timer.replaceAll(RegExp(r'[^0-9]'), '');
    int totalSeconds = int.tryParse(secStr) ?? 0;
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  String get formattedStopwatch {
    String secStr = stopwatch.replaceAll(RegExp(r'[^0-9]'), '');
    int totalSeconds = int.tryParse(secStr) ?? 0;
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void updateFromLine(String line) {
    if (line.startsWith("TIME=")) {
      time = line.substring(5);
    } else if (line.startsWith("DATE=")) {
      date = line.substring(5);
    } else if (line.startsWith("TEMP=")) {
      temperature = line.substring(5);
      if (!temperature.contains('°')) {
        temperature = temperature.replaceAll('C', '°C');
      }
    } else if (line.startsWith("MODE=")) {
      mode = line.substring(5);
    } else if (line.startsWith("AUTOMODE=")) {
      autoMode = line.substring(9);
    } else if (line.startsWith("ALARM=")) {
      alarm = line.substring(6);
      if (alarm == "OFF") {
        alarmState = "OFF";
      }
    } else if (line.startsWith("ALARM_STATE=")) {
      alarmState = line.substring(12);
    } else if (line == "ALARM:TRIGGERED") {
      alarmState = "TRIGGERED";
    } else if (line == "ALARM:STOPPED") {
      alarmState = "WAITING";
    } else if (line.startsWith("TIMER=")) {
      timer = line.substring(6);
    } else if (line.startsWith("TIMER_STATE=")) {
      timerState = line.substring(12);
    } else if (line == "TIMER:FINISHED") {
      timerState = "FINISHED";
    } else if (line.startsWith("STOPWATCH=")) {
      stopwatch = line.substring(10);
    } else if (line.startsWith("STOPWATCH_STATE=")) {
      stopwatchState = line.substring(16);
    }
  }
}

class BluetoothManager {
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? txCharacteristic; // App writes to ESP32 RX
  BluetoothCharacteristic? rxCharacteristic; // App reads from ESP32 TX

  bool get isConnected => connectedDevice != null && connectedDevice!.isConnected;

  final _statusController = StreamController<ClockStatus>.broadcast();
  Stream<ClockStatus> get statusStream => _statusController.stream;
  
  ClockStatus currentStatus = ClockStatus();

  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _rxSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    
    return statuses.values.every((status) => status.isGranted);
  }

  void startScan(Function(List<ScanResult>) onResults) {
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen(onResults);
    try {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Scan failed: $e");
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  Future<bool> connect(BluetoothDevice device, Function onDisconnect) async {
    try {
      await device.connect(license: License.nonprofit, autoConnect: false);
      connectedDevice = device;

      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _cleanUp();
          onDisconnect();
        }
      });

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        String sUuid = service.uuid.toString().toUpperCase();
        if (sUuid == "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") {
          for (BluetoothCharacteristic c in service.characteristics) {
            String cUuid = c.uuid.toString().toUpperCase();
            if (cUuid == "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") {
              txCharacteristic = c; // ESP32 RX UUID (App writes)
            } else if (cUuid == "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") {
              rxCharacteristic = c; // ESP32 TX UUID (App reads)
            }
          }
        }
      }

      if (rxCharacteristic != null && txCharacteristic != null) {
        await rxCharacteristic!.setNotifyValue(true);
        _rxSubscription = rxCharacteristic!.onValueReceived.listen((value) {
          String incoming = ascii.decode(value).trim();
          if (incoming.isNotEmpty) {
            List<String> lines = incoming.split(RegExp(r'\r?\n'));
            ClockStatus newStatus = currentStatus.copy();
            bool changed = false;
            for (String line in lines) {
              if (line.trim().isNotEmpty) {
                newStatus.updateFromLine(line.trim());
                changed = true;
              }
            }
            if (changed) {
              currentStatus = newStatus;
              _statusController.add(currentStatus);
            }
          }
        });
        return true;
      } else {
        await disconnect();
        return false;
      }
    } catch (e) {
      await disconnect();
      return false;
    }
  }

  void _cleanUp() {
    _rxSubscription?.cancel();
    _rxSubscription = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    connectedDevice = null;
    txCharacteristic = null;
    rxCharacteristic = null;
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }
    _cleanUp();
  }

  void sendCommand(String command) {
    if (isConnected && txCharacteristic != null) {
      txCharacteristic!.write(ascii.encode("$command\n"), withoutResponse: true);
    }
  }

  void dispose() {
    _statusController.close();
    disconnect();
  }
}
