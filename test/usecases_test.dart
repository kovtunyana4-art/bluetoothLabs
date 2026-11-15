import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth/domain/entities/ble_device_entity.dart';
import 'package:bluetooth/domain/entities/clock_status.dart';
import 'package:bluetooth/domain/interfaces/i_clock_repository.dart';
import 'package:bluetooth/application/usecases/connect_clock_usecase.dart';
import 'package:bluetooth/application/usecases/disconnect_clock_usecase.dart';
import 'package:bluetooth/application/usecases/send_clock_command_usecase.dart';
import 'package:bluetooth/application/usecases/sync_clock_time_usecase.dart';
import 'package:bluetooth/application/usecases/scan_clocks_usecase.dart';

class FakeClockRepository implements IClockRepository {
  bool _isConnected = false;
  BleDeviceEntity? _connectedDevice;
  final ClockStatus _status = ClockStatus();
  final List<String> sentCommands = [];
  bool scanStarted = false;
  bool scanStopped = false;

  @override
  bool get isConnected => _isConnected;

  @override
  ClockStatus get currentStatus => _status;

  @override
  Stream<ClockStatus> get statusStream => const Stream.empty();

  @override
  Stream<List<BleDeviceEntity>> get scanResultsStream => const Stream.empty();

  @override
  BleDeviceEntity? get connectedDevice => _connectedDevice;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  void startScan({void Function(List<BleDeviceEntity> results)? onResults}) {
    scanStarted = true;
    onResults?.call([const BleDeviceEntity(id: "1", name: "Test ESP32")]);
  }

  @override
  void stopScan() {
    scanStopped = true;
  }

  @override
  Future<bool> connect(BleDeviceEntity device, {void Function()? onDisconnect}) async {
    _isConnected = true;
    _connectedDevice = device;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    _connectedDevice = null;
  }

  @override
  void sendCommand(String command) {
    sentCommands.add(command);
  }

  @override
  void dispose() {}
}

void main() {
  group('Clean Architecture Use Cases (DIP Tests)', () {
    late FakeClockRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeClockRepository();
    });

    test('ScanClocksUseCase delegates scan operations to repository', () async {
      final useCase = ScanClocksUseCase(fakeRepository);

      expect(await useCase.requestPermissions(), isTrue);

      List<BleDeviceEntity>? captured;
      useCase.startScan(onResults: (results) {
        captured = results;
      });

      expect(fakeRepository.scanStarted, isTrue);
      expect(captured?.first.name, 'Test ESP32');

      useCase.stopScan();
      expect(fakeRepository.scanStopped, isTrue);
    });

    test('ConnectClockUseCase and DisconnectClockUseCase update connection state', () async {
      final connectUseCase = ConnectClockUseCase(fakeRepository);
      final disconnectUseCase = DisconnectClockUseCase(fakeRepository);

      const device = BleDeviceEntity(id: "DEV_01", name: "My Smart Clock");
      final connected = await connectUseCase.execute(device);

      expect(connected, isTrue);
      expect(fakeRepository.isConnected, isTrue);
      expect(fakeRepository.connectedDevice?.name, "My Smart Clock");

      await disconnectUseCase.execute();
      expect(fakeRepository.isConnected, isFalse);
      expect(fakeRepository.connectedDevice, isNull);
    });

    test('SendClockCommandUseCase sends command via abstraction', () {
      final sendCommandUseCase = SendClockCommandUseCase(fakeRepository);
      sendCommandUseCase.execute("DISPLAYTEMP");
      sendCommandUseCase.execute("AUTOMODE");

      expect(fakeRepository.sentCommands, ["DISPLAYTEMP", "AUTOMODE"]);
    });

    test('SyncClockTimeUseCase formats and dispatches DATETIME command', () {
      final syncTimeUseCase = SyncClockTimeUseCase(fakeRepository);
      final testDate = DateTime(2026, 11, 12, 14, 30, 45);

      syncTimeUseCase.execute(testDate);

      expect(fakeRepository.sentCommands, ["DATETIME=12.11.2026 14:30:45"]);
    });
  });
}
