import '../../domain/interfaces/i_clock_repository.dart';

/// Сценарій використання: Відправка команди на годинник (зміна режиму, будильник тощо)
class SendClockCommandUseCase {
  final IClockRepository _repository;

  SendClockCommandUseCase(this._repository);

  void execute(String command) {
    _repository.sendCommand(command);
  }
}
