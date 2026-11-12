import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Domain Layer
import 'domain/interfaces/i_clock_repository.dart';

// Application Layer (Use Cases)
import 'application/usecases/scan_clocks_usecase.dart';
import 'application/usecases/connect_clock_usecase.dart';
import 'application/usecases/disconnect_clock_usecase.dart';
import 'application/usecases/send_clock_command_usecase.dart';
import 'application/usecases/sync_clock_time_usecase.dart';

// Infrastructure Layer
import 'infrastructure/repositories/flutter_blue_clock_repository.dart';

// Presentation Layer
import 'presentation/notifiers/clock_notifier.dart';
import 'presentation/views/main_screen.dart';

// Реекспорт віджетів для забезпечення зворотної сумісності з тестами
export 'presentation/notifiers/clock_notifier.dart';
export 'presentation/views/main_screen.dart';
export 'presentation/views/clock_dashboard_view.dart';
export 'presentation/views/device_scanner_view.dart';
export 'presentation/widgets/clock_status_card.dart';
export 'presentation/widgets/display_mode_panel.dart';

/// Крок 11: Складання шарів через Dependency Injection (Composition Root).
/// У точці входу створюється конкретна реалізація репозиторію (Infrastructure)
/// і передається у Use Cases (Application), а вони — у Notifier (Presentation).
void main() {
  // 1. Infrastructure Layer: Конкретна реалізація репозиторію
  final IClockRepository clockRepository = FlutterBlueClockRepository();

  // 2. Application Layer: Сценарії використання з переданим репозиторієм
  final scanClocksUseCase = ScanClocksUseCase(clockRepository);
  final connectClockUseCase = ConnectClockUseCase(clockRepository);
  final disconnectClockUseCase = DisconnectClockUseCase(clockRepository);
  final sendClockCommandUseCase = SendClockCommandUseCase(clockRepository);
  final syncClockTimeUseCase = SyncClockTimeUseCase(clockRepository);

  // 3. Presentation Layer: Передача Use Cases у Presentation через конструктор (DIP)
  final clockNotifier = ClockNotifier(
    clockRepository: clockRepository,
    scanClocksUseCase: scanClocksUseCase,
    connectClockUseCase: connectClockUseCase,
    disconnectClockUseCase: disconnectClockUseCase,
    sendClockCommandUseCase: sendClockCommandUseCase,
    syncClockTimeUseCase: syncClockTimeUseCase,
  );

  runApp(
    ChangeNotifierProvider<ClockNotifier>.value(
      value: clockNotifier,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32-C3 Mini Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
