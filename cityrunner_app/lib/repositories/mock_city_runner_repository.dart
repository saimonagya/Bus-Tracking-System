import 'dart:math';

import '../models/city_runner_models.dart';
import 'city_runner_repository_base.dart';

/// Fake, fully in-memory backend so the app runs standalone with no server.
///
/// Behaves like a real API: has its own "database" of buses/drivers, issues
/// fake bearer tokens on login, persists mutations (seat toggles, bus
/// status, new drivers/buses) in memory for the lifetime of the app, and
/// adds a small artificial delay so loading states are visible.
///
/// Swap this for [CityRunnerRepository] in `main.dart` once your partner's
/// real backend is ready — nothing else in the app needs to change.
class MockCityRunnerRepository implements CityRunnerRepositoryBase {
  MockCityRunnerRepository() {
    _seedData();
  }

  final _random = Random();
  final Duration _latency = const Duration(milliseconds: 450);

  late List<_MockBus> _buses;
  late List<_MockDriver> _drivers;
  final _admin = _MockAdmin(
    id: 1,
    username: 'admin',
    displayName: 'Prakash Rai',
    password: 'admin123',
  );

  // token -> (role, ownerId)
  final Map<String, ({UserRole role, int ownerId})> _tokens = {};

  // ── Seed data ────────────────────────────────────────────────────────────

  void _seedData() {
    final route = [
      const Coordinate(lat: 27.3389, lng: 88.6065), // Gangtok
      const Coordinate(lat: 27.3450, lng: 88.6120),
      const Coordinate(lat: 27.3520, lng: 88.6210),
      const Coordinate(lat: 27.3600, lng: 88.6300), // Ranipool
    ];

    final stops = [
      Stop(
        id: 1,
        name: 'Gangtok Bus Stand',
        coordinate: route[0],
        fare: 0,
        orderIndex: 0,
      ),
      Stop(
        id: 2,
        name: 'Deorali',
        coordinate: route[1],
        fare: 20,
        orderIndex: 1,
      ),
      Stop(
        id: 3,
        name: 'Hope College',
        coordinate: route[2],
        fare: 35,
        orderIndex: 2,
      ),
      Stop(
        id: 4,
        name: 'Ranipool',
        coordinate: route[3],
        fare: 45,
        orderIndex: 3,
      ),
    ];

    _drivers = [
      _MockDriver(
        id: 1,
        username: 'driver1',
        displayName: 'Prakash Sharma',
        password: 'driver123',
        assignedBusId: 1,
      ),
      _MockDriver(
        id: 2,
        username: 'driver2',
        displayName: 'Anita Chettri',
        password: 'driver123',
        assignedBusId: 2,
      ),
    ];

    _buses = [
      _MockBus(
        id: 1,
        name: 'CityRunner AC Bus',
        registrationNumber: 'TN 38 N 1234',
        routeName: 'Gangtok -> Ranipool',
        seatCapacity: 24,
        isActive: true,
        currentStopIndex: 1,
        route: route,
        stops: stops,
        position: route[1],
        hasLiveLocation: true,
        locationUpdatedAt: DateTime.now().toUtc(),
        seats: _seedSeats(24, bookedIndexes: const {2, 6, 10, 14, 18}),
      ),
      _MockBus(
        id: 2,
        name: 'City Express',
        registrationNumber: 'TN 38 N 5678',
        routeName: 'Gangtok -> Ranipool',
        seatCapacity: 20,
        isActive: false,
        currentStopIndex: 0,
        route: route,
        stops: stops,
        position: route[0],
        hasLiveLocation: false,
        locationUpdatedAt: null,
        seats: _seedSeats(20, bookedIndexes: const {1, 4}),
      ),
      _MockBus(
        id: 3,
        name: 'City Ordinary',
        registrationNumber: 'TN 38 N 9012',
        routeName: 'Gangtok -> Ranipool',
        seatCapacity: 30,
        isActive: true,
        currentStopIndex: 2,
        route: route,
        stops: stops,
        position: route[2],
        hasLiveLocation: true,
        locationUpdatedAt: DateTime.now().toUtc().subtract(
          const Duration(minutes: 3),
        ),
        seats: _seedSeats(30, bookedIndexes: const {0, 3, 7, 12, 20, 25}),
      ),
    ];
  }

  List<Seat> _seedSeats(int count, {required Set<int> bookedIndexes}) {
    return List.generate(count, (index) {
      final row = index ~/ 4;
      final col = index % 4;
      return Seat(
        id: index + 1,
        seatCode: '${String.fromCharCode(65 + row)}${col + 1}',
        label: '${String.fromCharCode(65 + row)}${col + 1}',
        rowNumber: row,
        columnName: String.fromCharCode(65 + row),
        isBooked: bookedIndexes.contains(index),
      );
    });
  }

  // ── Public / passenger ──────────────────────────────────────────────────

  @override
  Future<List<BusState>> fetchPublicBuses() async {
    await _delay();
    _jitterActiveBuses();
    return _buses.map((b) => b.toBusState()).toList();
  }

  @override
  Future<LoginResult> login(String username, String password) async {
    await _delay();
    final uname = username.trim().toLowerCase();

    for (final driver in _drivers) {
      if (driver.username.toLowerCase() == uname) {
        if (driver.password != password) {
          return const LoginResult(
            success: false,
            message: 'Incorrect password.',
          );
        }
        final token = _issueToken(UserRole.driver, driver.id);
        return LoginResult(
          success: true,
          message: 'Welcome back, ${driver.displayName}.',
          token: token,
          user: driver.toSessionUser(),
        );
      }
    }

    if (_admin.username.toLowerCase() == uname) {
      if (_admin.password != password) {
        return const LoginResult(
          success: false,
          message: 'Incorrect password.',
        );
      }
      final token = _issueToken(UserRole.admin, _admin.id);
      return LoginResult(
        success: true,
        message: 'Welcome back, ${_admin.displayName}.',
        token: token,
        user: _admin.toSessionUser(),
      );
    }

    return const LoginResult(
      success: false,
      message: 'No account found for that username.',
    );
  }

  @override
  Future<SessionUser> fetchCurrentUser(String token) async {
    await _delay();
    final session = _requireSession(token);
    if (session.role == UserRole.admin) return _admin.toSessionUser();
    return _requireDriver(session.ownerId).toSessionUser();
  }

  @override
  Future<MutationResult> changePassword(
    String token,
    String currentPassword,
    String newPassword,
  ) async {
    await _delay();
    final session = _requireSession(token);
    if (session.role == UserRole.admin) {
      if (_admin.password != currentPassword) {
        return const MutationResult(
          success: false,
          message: 'Current password is incorrect.',
        );
      }
      _admin.password = newPassword;
      _admin.mustChangePassword = false;
    } else {
      final driver = _requireDriver(session.ownerId);
      if (driver.password != currentPassword) {
        return const MutationResult(
          success: false,
          message: 'Current password is incorrect.',
        );
      }
      driver.password = newPassword;
      driver.mustChangePassword = false;
    }
    return const MutationResult(success: true, message: 'Password updated.');
  }

  // ── Driver ───────────────────────────────────────────────────────────────

  @override
  Future<DriverDashboard> fetchDriverDashboard(String token) async {
    await _delay();
    final session = _requireSession(token, expected: UserRole.driver);
    final driver = _requireDriver(session.ownerId);
    final bus = _busFor(driver.assignedBusId);
    return DriverDashboard(
      user: driver.toSessionUser(),
      bus: bus?.toBusState(),
    );
  }

  @override
  Future<MutationResult> updateDriverLocation(
    String token,
    double lat,
    double lng,
    double? accuracyMeters,
  ) async {
    await _delay(const Duration(milliseconds: 150));
    final session = _requireSession(token, expected: UserRole.driver);
    final driver = _requireDriver(session.ownerId);
    final bus = _busFor(driver.assignedBusId);
    if (bus == null) {
      return const MutationResult(
        success: false,
        message: 'No bus assigned to this driver.',
      );
    }
    bus.position = Coordinate(lat: lat, lng: lng);
    bus.hasLiveLocation = true;
    bus.locationUpdatedAt = DateTime.now().toUtc();
    return const MutationResult(success: true, message: 'Location updated.');
  }

  @override
  Future<MutationResult> toggleDriverSeat(String token, int seatId) async {
    await _delay();
    final session = _requireSession(token, expected: UserRole.driver);
    final driver = _requireDriver(session.ownerId);
    final bus = _busFor(driver.assignedBusId);
    if (bus == null) {
      return const MutationResult(
        success: false,
        message: 'No bus assigned to this driver.',
      );
    }
    final index = bus.seats.indexWhere((s) => s.id == seatId);
    if (index == -1) {
      return const MutationResult(success: false, message: 'Seat not found.');
    }
    final seat = bus.seats[index];
    bus.seats[index] = Seat(
      id: seat.id,
      seatCode: seat.seatCode,
      label: seat.label,
      rowNumber: seat.rowNumber,
      columnName: seat.columnName,
      isBooked: !seat.isBooked,
    );
    return MutationResult(
      success: true,
      message: bus.seats[index].isBooked
          ? 'Seat ${seat.label} marked booked.'
          : 'Seat ${seat.label} released.',
    );
  }

  @override
  Future<MutationResult> resetDriverSeats(String token) async {
    await _delay();
    final session = _requireSession(token, expected: UserRole.driver);
    final driver = _requireDriver(session.ownerId);
    final bus = _busFor(driver.assignedBusId);
    if (bus == null) {
      return const MutationResult(
        success: false,
        message: 'No bus assigned to this driver.',
      );
    }
    bus.seats = bus.seats
        .map(
          (seat) => Seat(
            id: seat.id,
            seatCode: seat.seatCode,
            label: seat.label,
            rowNumber: seat.rowNumber,
            columnName: seat.columnName,
            isBooked: false,
          ),
        )
        .toList();
    return const MutationResult(success: true, message: 'All seats reset.');
  }

  @override
  Future<MutationResult> toggleDriverBus(String token) async {
    await _delay();
    final session = _requireSession(token, expected: UserRole.driver);
    final driver = _requireDriver(session.ownerId);
    final bus = _busFor(driver.assignedBusId);
    if (bus == null) {
      return const MutationResult(
        success: false,
        message: 'No bus assigned to this driver.',
      );
    }
    bus.isActive = !bus.isActive;
    return MutationResult(
      success: true,
      message: bus.isActive ? 'You are now online.' : 'You are now offline.',
    );
  }

  // ── Admin ────────────────────────────────────────────────────────────────

  @override
  Future<AdminOverview> fetchAdminOverview(String token) async {
    await _delay();
    _requireSession(token, expected: UserRole.admin);
    return AdminOverview(
      buses: _buses.map((b) => b.toBusState()).toList(),
      drivers: _drivers
          .map((d) => d.toSummary(busName: _busFor(d.assignedBusId)?.name))
          .toList(),
    );
  }

  @override
  Future<MutationResult> createBus(
    String token,
    String name,
    String registrationNumber,
    String routeName,
  ) async {
    await _delay();
    _requireSession(token, expected: UserRole.admin);
    final newId = (_buses.map((b) => b.id).fold<int>(0, max)) + 1;
    _buses.add(
      _MockBus(
        id: newId,
        name: name,
        registrationNumber: registrationNumber,
        routeName: routeName,
        seatCapacity: 24,
        isActive: false,
        currentStopIndex: 0,
        route: _buses.first.route,
        stops: _buses.first.stops,
        position: _buses.first.route.first,
        hasLiveLocation: false,
        locationUpdatedAt: null,
        seats: _seedSeats(24, bookedIndexes: const {}),
      ),
    );
    return MutationResult(success: true, message: 'Bus "$name" created.');
  }

  @override
  Future<MutationResult> createDriver(
    String token,
    String username,
    String displayName,
    String password,
    int? assignedBusId,
  ) async {
    await _delay();
    _requireSession(token, expected: UserRole.admin);
    if (_drivers.any(
      (d) => d.username.toLowerCase() == username.trim().toLowerCase(),
    )) {
      return const MutationResult(
        success: false,
        message: 'That username is already taken.',
      );
    }
    final newId = (_drivers.map((d) => d.id).fold<int>(0, max)) + 1;
    _drivers.add(
      _MockDriver(
        id: newId,
        username: username.trim(),
        displayName: displayName.trim(),
        password: password,
        assignedBusId: assignedBusId,
      ),
    );
    return MutationResult(
      success: true,
      message: 'Driver "$displayName" created.',
    );
  }

  @override
  Future<MutationResult> resetDriverPassword(
    String token,
    int driverId,
    String newPassword,
  ) async {
    await _delay();
    _requireSession(token, expected: UserRole.admin);
    final driver = _requireDriver(driverId);
    driver.password = newPassword;
    driver.mustChangePassword = true;
    return MutationResult(
      success: true,
      message: "${driver.displayName}'s password was reset.",
    );
  }

  @override
  Future<MutationResult> removeDriver(
    String token,
    int driverId,
    String adminPassword,
  ) async {
    await _delay();
    _requireSession(token, expected: UserRole.admin);
    if (_admin.password != adminPassword) {
      return const MutationResult(
        success: false,
        message: 'Admin password is incorrect.',
      );
    }
    final driver = _requireDriver(driverId);
    _drivers.removeWhere((d) => d.id == driverId);
    return MutationResult(
      success: true,
      message: '${driver.displayName} was removed.',
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _delay([Duration? override]) =>
      Future.delayed(override ?? _latency);

  String _issueToken(UserRole role, int ownerId) {
    final token = 'mock-${role.name}-$ownerId-${_random.nextInt(999999)}';
    _tokens[token] = (role: role, ownerId: ownerId);
    return token;
  }

  ({UserRole role, int ownerId}) _requireSession(
    String token, {
    UserRole? expected,
  }) {
    final session = _tokens[token];
    if (session == null) {
      throw StateError('Session expired. Please log in again.');
    }
    if (expected != null && session.role != expected) {
      throw StateError('This action requires a ${expected.name} account.');
    }
    return session;
  }

  _MockDriver _requireDriver(int id) {
    return _drivers.firstWhere(
      (d) => d.id == id,
      orElse: () => throw StateError('Driver not found.'),
    );
  }

  _MockBus? _busFor(int? busId) {
    if (busId == null) return null;
    for (final bus in _buses) {
      if (bus.id == busId) return bus;
    }
    return null;
  }

  /// Nudges active buses a little along their route + tweaks ETA each time
  /// public data is refreshed, so the map and tracking screen feel "live"
  /// even without a real driver phone pushing GPS updates.
  void _jitterActiveBuses() {
    for (final bus in _buses) {
      if (!bus.isActive || bus.route.length < 2) continue;
      final segment = _random.nextInt(bus.route.length);
      final base = bus.route[segment];
      bus.position = Coordinate(
        lat: base.lat + (_random.nextDouble() - 0.5) * 0.001,
        lng: base.lng + (_random.nextDouble() - 0.5) * 0.001,
      );
      bus.hasLiveLocation = true;
      bus.locationUpdatedAt = DateTime.now().toUtc();
    }
  }
}

// ── Internal mutable "database" rows ──────────────────────────────────────

class _MockBus {
  _MockBus({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.routeName,
    required this.seatCapacity,
    required this.isActive,
    required this.currentStopIndex,
    required this.route,
    required this.stops,
    required this.position,
    required this.hasLiveLocation,
    required this.locationUpdatedAt,
    required this.seats,
  });

  final int id;
  final String name;
  final String registrationNumber;
  final String routeName;
  final int seatCapacity;
  bool isActive;
  int currentStopIndex;
  final List<Coordinate> route;
  final List<Stop> stops;
  Coordinate position;
  bool hasLiveLocation;
  DateTime? locationUpdatedAt;
  List<Seat> seats;

  BusState toBusState() {
    final booked = seats.where((s) => s.isBooked).length;
    return BusState(
      id: id,
      name: name,
      registrationNumber: registrationNumber,
      routeName: routeName,
      seatCapacity: seatCapacity,
      isActive: isActive,
      currentStopIndex: currentStopIndex,
      etaMinutes: isActive ? 4 + (id * 2) % 11 : null,
      availableSeats: seatCapacity - booked,
      hasLiveLocation: hasLiveLocation,
      locationUpdatedAt: locationUpdatedAt,
      position: position,
      route: route,
      stops: stops,
      seats: seats,
    );
  }
}

class _MockDriver {
  _MockDriver({
    required this.id,
    required this.username,
    required this.displayName,
    required this.password,
    required this.assignedBusId,
  });

  final int id;
  final String username;
  final String displayName;
  String password;
  int? assignedBusId;
  bool mustChangePassword = false;

  SessionUser toSessionUser() => SessionUser(
    id: id,
    username: username,
    displayName: displayName,
    role: UserRole.driver,
    assignedBusId: assignedBusId,
    mustChangePassword: mustChangePassword,
  );

  DriverSummary toSummary({String? busName}) => DriverSummary(
    id: id,
    username: username,
    displayName: displayName,
    isActive: true,
    mustChangePassword: mustChangePassword,
    assignedBusId: assignedBusId,
    assignedBusName: busName,
  );
}

class _MockAdmin {
  _MockAdmin({
    required this.id,
    required this.username,
    required this.displayName,
    required this.password,
  });

  final int id;
  final String username;
  final String displayName;
  String password;
  bool mustChangePassword = false;

  SessionUser toSessionUser() => SessionUser(
    id: id,
    username: username,
    displayName: displayName,
    role: UserRole.admin,
    assignedBusId: null,
    mustChangePassword: mustChangePassword,
  );
}
