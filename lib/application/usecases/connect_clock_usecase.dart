import '../../domain/entities/ble_device_entity.dart';
import '../../domain/interfaces/i_clock_repository.dart';

/// Сценарій використання: Підключення до годинника
class ConnectClockUseCase {
  final IClockRepository _repository;

  ConnectClockUseCase(this._repository);

  Future<bool> execute(BleDeviceEntity device, {void Function()? onDisconnect}) {
    return _repository.connect(device, onDisconnect: onDisconnect);
  }
}
