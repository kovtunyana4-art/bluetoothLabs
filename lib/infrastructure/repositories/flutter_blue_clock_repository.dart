import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/ble_device_entity.dart';
import '../../domain/entities/clock_status.dart';
import '../../domain/interfaces/i_clock_repository.dart';
import '../config/app_config.dart';

/// Реалізація IClockRepository через бібліотеку flutter_blue_plus (Infrastructure Layer).
/// Повністю інкапсулює роботу з драйвером Bluetooth та конкретними UUID пристрою.
class FlutterBlueClockRepository implements IClockRepository {
  final AppConfig config;

  BluetoothDevice? _connectedBleDevice;
  BleDeviceEntity? _connectedDeviceEntity;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;

  ClockStatus _currentStatus = ClockStatus();
  final StreamController<ClockStatus> _statusController = StreamController<ClockStatus>.broadcast();
  final StreamController<List<BleDeviceEntity>> _scanResultsController = StreamController<List<BleDeviceEntity>>.broadcast();

  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _rxSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  FlutterBlueClockRepository({this.config = const AppConfig()});

  @override
  bool get isConnected => _connectedBleDevice != null && _connectedBleDevice!.isConnected;

  @override
  ClockStatus get currentStatus => _currentStatus;

  @override
  Stream<ClockStatus> get statusStream => _statusController.stream;

  @override
  Stream<List<BleDeviceEntity>> get scanResultsStream => _scanResultsController.stream;

  @override
  BleDeviceEntity? get connectedDevice => _connectedDeviceEntity;

  @override
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  @override
  void startScan({void Function(List<BleDeviceEntity> results)? onResults}) {
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final entities = results.map((r) {
        String name = r.device.platformName;
        if (name.isEmpty && r.advertisementData.advName.isNotEmpty) {
          name = r.advertisementData.advName;
        }
        return BleDeviceEntity(
          id: r.device.remoteId.str,
          name: name,
          rssi: r.rssi,
        );
      }).toList();

      _scanResultsController.add(entities);
      onResults?.call(entities);
    });

    try {
      FlutterBluePlus.startScan(timeout: config.scanTimeout);
    } catch (e) {
      debugPrint("Scan failed: $e");
    }
  }

  @override
  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  @override
  Future<bool> connect(BleDeviceEntity device, {void Function()? onDisconnect}) async {
    try {
      final bleDevice = BluetoothDevice.fromId(device.id);
      await bleDevice.connect(license: License.nonprofit, autoConnect: false);
      _connectedBleDevice = bleDevice;
      _connectedDeviceEntity = device;

      _connectionStateSubscription = bleDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _cleanUp();
          onDisconnect?.call();
        }
      });

      final services = await bleDevice.discoverServices();
      for (final service in services) {
        final sUuid = service.uuid.toString().toUpperCase();
        if (sUuid == config.serviceUuid) {
          for (final c in service.characteristics) {
            final cUuid = c.uuid.toString().toUpperCase();
            if (cUuid == config.txCharacteristicUuid) {
              _txCharacteristic = c;
            } else if (cUuid == config.rxCharacteristicUuid) {
              _rxCharacteristic = c;
            }
          }
        }
      }

      if (_rxCharacteristic != null && _txCharacteristic != null) {
        await _rxCharacteristic!.setNotifyValue(true);
        _rxSubscription = _rxCharacteristic!.onValueReceived.listen((value) {
          final incoming = ascii.decode(value).trim();
          if (incoming.isNotEmpty) {
            final lines = incoming.split(RegExp(r'\r?\n'));
            final newStatus = _currentStatus.copy();
            bool changed = false;
            for (final line in lines) {
              if (line.trim().isNotEmpty) {
                newStatus.updateFromLine(line.trim());
                changed = true;
              }
            }
            if (changed) {
              _currentStatus = newStatus;
              _statusController.add(_currentStatus);
            }
          }
        });
        return true;
      } else {
        await disconnect();
        return false;
      }
    } catch (e) {
      debugPrint("Error connecting to device: $e");
      await disconnect();
      return false;
    }
  }

  void _cleanUp() {
    _rxSubscription?.cancel();
    _rxSubscription = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _connectedBleDevice = null;
    _connectedDeviceEntity = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
  }

  @override
  Future<void> disconnect() async {
    if (_connectedBleDevice != null) {
      await _connectedBleDevice!.disconnect();
    }
    _cleanUp();
  }

  @override
  void sendCommand(String command) {
    if (isConnected && _txCharacteristic != null) {
      _txCharacteristic!.write(ascii.encode("$command\n"), withoutResponse: true);
    }
  }

  @override
  void dispose() {
    _statusController.close();
    _scanResultsController.close();
    disconnect();
  }
}
