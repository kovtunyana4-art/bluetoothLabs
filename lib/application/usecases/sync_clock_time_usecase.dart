import 'package:intl/intl.dart';
import '../../domain/interfaces/i_clock_repository.dart';

/// Сценарій використання: Синхронізація поточного часу смартфона з годинником
class SyncClockTimeUseCase {
  final IClockRepository _repository;

  SyncClockTimeUseCase(this._repository);

  void execute([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    final datetimeCmd = "DATETIME=${DateFormat('dd.MM.yyyy HH:mm:ss').format(now)}";
    _repository.sendCommand(datetimeCmd);
  }
}
