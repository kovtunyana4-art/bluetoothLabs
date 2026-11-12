/// Конфігурація підключення та параметрів застосунку (Infrastructure Layer)
class AppConfig {
  final String appTitle;
  final Duration scanTimeout;
  final String serviceUuid;
  final String txCharacteristicUuid;
  final String rxCharacteristicUuid;

  const AppConfig({
    this.appTitle = "ESP32-C3 Mini Clock",
    this.scanTimeout = const Duration(seconds: 5),
    this.serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E",
    this.txCharacteristicUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E",
    this.rxCharacteristicUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E",
  });
}
