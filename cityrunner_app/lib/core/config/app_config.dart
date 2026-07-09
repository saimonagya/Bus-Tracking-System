class AppConfig {
  const AppConfig._();

  /// Set to `false` once your partner's real backend is ready, or override
  /// per-run without touching code:
  ///   flutter run --dart-define=USE_MOCK_BACKEND=false \
  ///     --dart-define=CITY_RUNNER_API_BASE_URL=https://your-partners-api.com
  ///
  /// With this flag true, the whole app runs standalone against
  /// [MockCityRunnerRepository] — no server required.
  static const useMockBackend = bool.fromEnvironment(
    'USE_MOCK_BACKEND',
    defaultValue: true,
  );
}
