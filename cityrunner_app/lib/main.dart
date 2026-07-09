import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'repositories/city_runner_repository.dart';
import 'repositories/city_runner_repository_base.dart';
import 'repositories/mock_city_runner_repository.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CityRunnerApp());
}

/// Chooses the data source for the whole app. Flip [AppConfig.useMockBackend]
/// (or pass --dart-define=USE_MOCK_BACKEND=false) once a real backend exists.
CityRunnerRepositoryBase _buildRepository() {
  if (AppConfig.useMockBackend) {
    return MockCityRunnerRepository();
  }
  return CityRunnerRepository(ApiService());
}

class CityRunnerApp extends StatelessWidget {
  const CityRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(_buildRepository())..bootstrap(),
      child: MaterialApp(
        title: 'City Runner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.splash,
      ),
    );
  }
}
