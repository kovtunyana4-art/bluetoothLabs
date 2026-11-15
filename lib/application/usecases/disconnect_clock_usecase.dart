import '../../domain/interfaces/i_clock_repository.dart';

/// Сценарій використання: Відключення від годинника
class DisconnectClockUseCase {
  final IClockRepository _repository;

  DisconnectClockUseCase(this._repository);

  Future<void> execute() {
    return _repository.disconnect();
  }
}
