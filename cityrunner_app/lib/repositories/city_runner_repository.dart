import '../models/city_runner_models.dart';
import '../services/api_service.dart';
import 'city_runner_repository_base.dart';

/// Real backend implementation — talks to an actual REST API via [ApiService].
/// Point [ApiService]'s base URL at your partner's backend and use this
/// instead of [MockCityRunnerRepository] once it's ready.
class CityRunnerRepository implements CityRunnerRepositoryBase {
  const CityRunnerRepository(this._api);

  final ApiService _api;

  @override
  Future<List<BusState>> fetchPublicBuses() async {
    final data = await _api.get('/api/public/buses');
    return (data['buses'] as List<dynamic>)
        .map((item) => BusState.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LoginResult> login(String username, String password) async {
    return LoginResult.fromJson(
      await _api.post(
        '/api/auth/login',
        data: {'username': username, 'password': password},
      ),
    );
  }

  @override
  Future<SessionUser> fetchCurrentUser(String token) async {
    return SessionUser.fromJson(await _api.get('/api/auth/me', token: token));
  }

  @override
  Future<MutationResult> changePassword(
    String token,
    String currentPassword,
    String newPassword,
  ) async {
    return MutationResult.fromJson(
      await _api.post(
        '/api/auth/change-password',
        token: token,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      ),
    );
  }

  @override
  Future<DriverDashboard> fetchDriverDashboard(String token) async {
    return DriverDashboard.fromJson(
      await _api.get('/api/driver/dashboard', token: token),
    );
  }

  @override
  Future<MutationResult> updateDriverLocation(
    String token,
    double lat,
    double lng,
    double? accuracyMeters,
  ) async {
    return MutationResult.fromJson(
      await _api.post(
        '/api/driver/location',
        token: token,
        data: {'lat': lat, 'lng': lng, 'accuracy_meters': accuracyMeters},
      ),
    );
  }

  @override
  Future<MutationResult> toggleDriverSeat(String token, int seatId) async {
    return MutationResult.fromJson(
      await _api.post('/api/driver/seats/$seatId/toggle', token: token),
    );
  }

  @override
  Future<MutationResult> resetDriverSeats(String token) async {
    return MutationResult.fromJson(
      await _api.post('/api/driver/seats/reset', token: token),
    );
  }

  @override
  Future<MutationResult> toggleDriverBus(String token) async {
    return MutationResult.fromJson(
      await _api.post('/api/driver/bus/toggle-active', token: token),
    );
  }

  @override
  Future<AdminOverview> fetchAdminOverview(String token) async {
    return AdminOverview.fromJson(
      await _api.get('/api/admin/overview', token: token),
    );
  }

  @override
  Future<MutationResult> createBus(
    String token,
    String name,
    String registrationNumber,
    String routeName,
  ) async {
    return MutationResult.fromJson(
      await _api.post(
        '/api/admin/buses',
        token: token,
        data: {
          'name': name,
          'registration_number': registrationNumber,
          'route_name': routeName,
        },
      ),
    );
  }

  @override
  Future<MutationResult> createDriver(
    String token,
    String username,
    String displayName,
    String password,
    int? assignedBusId,
  ) async {
    return MutationResult.fromJson(
      await _api.post(
        '/api/admin/drivers',
        token: token,
        data: {
          'username': username,
          'display_name': displayName,
          'password': password,
          'assigned_bus_id': assignedBusId,
        },
      ),
    );
  }

  @override
  Future<MutationResult> resetDriverPassword(
    String token,
    int driverId,
    String newPassword,
  ) async {
    return MutationResult.fromJson(
      await _api.post(
        '/api/admin/drivers/$driverId/reset-password',
        token: token,
        data: {'new_password': newPassword},
      ),
    );
  }

  @override
  Future<MutationResult> removeDriver(
    String token,
    int driverId,
    String adminPassword,
  ) async {
    return MutationResult.fromJson(
      await _api.delete(
        '/api/admin/drivers/$driverId',
        token: token,
        data: {'admin_password': adminPassword},
      ),
    );
  }
}
