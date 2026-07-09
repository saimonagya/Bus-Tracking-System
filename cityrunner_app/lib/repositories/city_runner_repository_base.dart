import '../models/city_runner_models.dart';

/// Contract shared by every backend implementation (mock or real API).
///
/// [AppProvider] only ever talks to this interface, never to a concrete
/// class. That means swapping the mock data source for a real backend
/// later is a one-line change in `main.dart` — nothing in the screens,
/// widgets, or provider needs to change, as long as the real backend
/// returns JSON shaped the way the `fromJson` factories in
/// `models/city_runner_models.dart` expect.
abstract class CityRunnerRepositoryBase {
  Future<List<BusState>> fetchPublicBuses();

  Future<LoginResult> login(String username, String password);

  Future<SessionUser> fetchCurrentUser(String token);

  Future<MutationResult> changePassword(
    String token,
    String currentPassword,
    String newPassword,
  );

  Future<DriverDashboard> fetchDriverDashboard(String token);

  Future<MutationResult> updateDriverLocation(
    String token,
    double lat,
    double lng,
    double? accuracyMeters,
  );

  Future<MutationResult> toggleDriverSeat(String token, int seatId);

  Future<MutationResult> resetDriverSeats(String token);

  Future<MutationResult> toggleDriverBus(String token);

  Future<AdminOverview> fetchAdminOverview(String token);

  Future<MutationResult> createBus(
    String token,
    String name,
    String registrationNumber,
    String routeName,
  );

  Future<MutationResult> createDriver(
    String token,
    String username,
    String displayName,
    String password,
    int? assignedBusId,
  );

  Future<MutationResult> resetDriverPassword(
    String token,
    int driverId,
    String newPassword,
  );

  Future<MutationResult> removeDriver(
    String token,
    int driverId,
    String adminPassword,
  );
}
