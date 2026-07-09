class AppConstants {
  const AppConstants._();

  static const appName = 'City Runner';
  static const tagline = 'Move Cities. Move People.';
  static const apiBaseUrl = String.fromEnvironment(
    'CITY_RUNNER_API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  static const driverTokenKey = 'city-runner-driver-token';
  static const adminTokenKey = 'city-runner-admin-token';
  static const fullRouteFare = 60;
  static const defaultRouteName = 'Gangtok -> Ranipool';
  static const publicPollSeconds = 8;
  static const driverPollSeconds = 6;
  static const adminPollSeconds = 8;
}
