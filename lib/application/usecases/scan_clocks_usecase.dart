import '../../domain/entities/ble_device_entity.dart';
import '../../domain/interfaces/i_clock_repository.dart';

/// Сценарій використання: Сканування BLE-пристроїв годинника
class ScanClocksUseCase {
  final IClockRepository _repository;

  ScanClocksUseCase(this._repository);

  Stream<List<BleDeviceEntity>> get scanResultsStream => _repository.scanResultsStream;

  Future<bool> requestPermissions() => _repository.requestPermissions();

  void startScan({void Function(List<BleDeviceEntity>)? onResults}) {
    _repository.startScan(onResults: onResults);
  }

  void stopScan() {
    _repository.stopScan();
  }
}
