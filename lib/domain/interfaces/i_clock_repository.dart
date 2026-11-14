import 'dart:async';
import '../entities/clock_status.dart';
import '../entities/ble_device_entity.dart';

/// Інтерфейс репозиторію годинника (Domain Layer).
/// Описує контракт для роботи з годинником без прив'язки
/// до конкретної платформи чи бібліотеки передачі даних (DIP).
/// Дозволяє замінювати драйвер зв'язку (BLE, TCP/IP, Mock тощо) без змін у бізнес-логіці.
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
  /// [onResults] — необов'язковий зворотний виклик для швидкої реакції на оновлення списку
  void startScan({void Function(List<BleDeviceEntity> results)? onResults});

  /// Зупинка сканування
  void stopScan();

  /// Підключення до пристрою
  /// [device] — цільовий BLE пристрій
  /// [onDisconnect] — зворотний виклик при раптовому обриві зв'язку
  Future<bool> connect(BleDeviceEntity device, {void Function()? onDisconnect});

  /// Відключення від поточного пристрою
  Future<void> disconnect();

  /// Відправка команди годиннику (наприклад, SETTIME, ALARM, TIMER тощо)
  /// [command] — рядок текстового протоколу зв'язку
  void sendCommand(String command);

  /// Звільнення ресурсів та закриття відкритих потоків
  void dispose();
}
