import 'dart:async';
import '../entities/clock_status.dart';
import '../entities/ble_device_entity.dart';

/// Інтерфейс репозиторію годинника (Domain Layer).
/// Описує контракт для роботи з годинником без прив'язки
/// до конкретної платформи чи бібліотеки передачі даних (DIP).
abstract class IClockRepository {
  /// Чи є активне з'єднання з годинником
  bool get isConnected;

  /// Поточний стан годинника
  ClockStatus get currentStatus;

  /// Потік оновлень стану годинника
  Stream<ClockStatus> get statusStream;

  /// Потік результатів сканування доступних BLE пристроїв
  Stream<List<BleDeviceEntity>> get scanResultsStream;

  /// Підключений пристрій (або null)
  BleDeviceEntity? get connectedDevice;

  /// Запит необхідних дозволів (Bluetooth, Location тощо)
  Future<bool> requestPermissions();

  /// Запуск сканування BLE-пристроїв
  void startScan({void Function(List<BleDeviceEntity> results)? onResults});

  /// Зупинка сканування
  void stopScan();

  /// Підключення до пристрою
  Future<bool> connect(BleDeviceEntity device, {void Function()? onDisconnect});

  /// Відключення від поточного пристрою
  Future<void> disconnect();

  /// Відправка команди годиннику (наприклад, SETTIME, ALARM, TIMER тощо)
  void sendCommand(String command);

  /// Звільнення ресурсів
  void dispose();
}
