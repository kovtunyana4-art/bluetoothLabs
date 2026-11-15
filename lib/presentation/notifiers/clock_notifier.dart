import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/ble_device_entity.dart';
import '../../domain/entities/clock_status.dart';
import '../../domain/interfaces/i_clock_repository.dart';
import '../../application/usecases/scan_clocks_usecase.dart';
import '../../application/usecases/connect_clock_usecase.dart';
import '../../application/usecases/disconnect_clock_usecase.dart';
import '../../application/usecases/send_clock_command_usecase.dart';
import '../../application/usecases/sync_clock_time_usecase.dart';
import '../../infrastructure/repositories/mock_clock_repository.dart';

/// Presentation Notifier для управління станом UI годинника.
/// Отримує залежності через конструктор (DIP / Dependency Injection).
class ClockNotifier extends ChangeNotifier {
  final IClockRepository _repository;
  final ScanClocksUseCase _scanClocksUseCase;
  final ConnectClockUseCase _connectClockUseCase;
  final DisconnectClockUseCase _disconnectClockUseCase;
  final SendClockCommandUseCase _sendClockCommandUseCase;
  final SyncClockTimeUseCase _syncClockTimeUseCase;

  bool _showMockDashboard = true;
  bool _isScanning = false;
  bool _isDisposed = false;
  List<BleDeviceEntity> _scanResults = [];

  Timer? _mockTimer;
  Timer? _pollTimer;
  Timer? _scanTimer;
  StreamSubscription<ClockStatus>? _statusSubscription;
  StreamSubscription<List<BleDeviceEntity>>? _scanSubscription;

  factory ClockNotifier({
    IClockRepository? clockRepository,
    ScanClocksUseCase? scanClocksUseCase,
    ConnectClockUseCase? connectClockUseCase,
    DisconnectClockUseCase? disconnectClockUseCase,
    SendClockCommandUseCase? sendClockCommandUseCase,
    SyncClockTimeUseCase? syncClockTimeUseCase,
  }) {
    final repo = clockRepository ?? MockClockRepository();
    return ClockNotifier._(
      repo,
      scanClocksUseCase ?? ScanClocksUseCase(repo),
      connectClockUseCase ?? ConnectClockUseCase(repo),
      disconnectClockUseCase ?? DisconnectClockUseCase(repo),
      sendClockCommandUseCase ?? SendClockCommandUseCase(repo),
      syncClockTimeUseCase ?? SyncClockTimeUseCase(repo),
    );
  }

  ClockNotifier._(
    this._repository,
    this._scanClocksUseCase,
    this._connectClockUseCase,
    this._disconnectClockUseCase,
    this._sendClockCommandUseCase,
    this._syncClockTimeUseCase,
  ) {
    _startMockUpdates();
    _startPolling();
    _listenToStreams();
    startScan();
  }

  bool get showMockDashboard => _showMockDashboard;
  bool get isScanning => _isScanning;
  List<BleDeviceEntity> get scanResults => _scanResults;
  bool get isConnected => _repository.isConnected;
  ClockStatus get status => _repository.currentStatus;
  BleDeviceEntity? get connectedDevice => _repository.connectedDevice;

  String get connectedDeviceName {
    if (_repository.connectedDevice == null) return "";
    return _repository.connectedDevice!.displayName;
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void _listenToStreams() {
    _statusSubscription = _repository.statusStream.listen((_) {
      notifyListeners();
    });

    _scanSubscription = _repository.scanResultsStream.listen((results) {
      _scanResults = results;
      notifyListeners();
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_repository.isConnected && !_showMockDashboard) {
        _sendClockCommandUseCase.execute("STATUS");
      }
    });
  }

  void _startMockUpdates() {
    _mockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_showMockDashboard && !_repository.isConnected) {
        final now = DateTime.now();
        _repository.currentStatus.time = DateFormat('HH:mm:ss').format(now);
        _repository.currentStatus.date = DateFormat('dd.MM.yyyy').format(now);
        final temp = 24.0 + (now.second % 5) * 0.2;
        _repository.currentStatus.temperature = "${temp.toStringAsFixed(1)}°C";
        notifyListeners();
      }
    });
  }

  Future<void> startScan({void Function(String message)? onMessage}) async {
    _scanResults = [];
    _isScanning = true;
    notifyListeners();

    try {
      final permissionsGranted = await _scanClocksUseCase.requestPermissions();
      if (!permissionsGranted) {
        onMessage?.call("Надайте дозволи для Bluetooth/Локації");
      }

      _scanClocksUseCase.startScan(onResults: (results) {
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
    BleDeviceEntity device, {
    void Function(String message)? onMessage,
  }) async {
    _scanClocksUseCase.stopScan();
    _showMockDashboard = false;
    notifyListeners();

    onMessage?.call("Підключення до ${device.displayName}...");

    final success = await _connectClockUseCase.execute(
      device,
      onDisconnect: () {
        notifyListeners();
        onMessage?.call("Пристрій відключено");
        startScan(onMessage: onMessage);
      },
    );

    if (success) {
      _syncClockTimeUseCase.execute();
    } else {
      onMessage?.call("Не вдалося підключитися (не знайдено сервісу/характеристик)");
    }

    notifyListeners();
    return success;
  }

  Future<void> disconnect() async {
    await _disconnectClockUseCase.execute();
    notifyListeners();
    startScan();
  }

  void setShowMockDashboard(bool value) {
    _showMockDashboard = value;
    notifyListeners();
  }

  void sendCommand(String command) {
    if (_repository.isConnected) {
      _sendClockCommandUseCase.execute(command);
    } else if (_showMockDashboard) {
      // Демо/мок реакція на команди
      _repository.sendCommand(command);
      notifyListeners();
    }
  }

  void syncTime() {
    _syncClockTimeUseCase.execute();
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
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _repository.stopScan();
    _repository.dispose();
    super.dispose();
  }
}
