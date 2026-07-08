import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/geo_utils.dart';
import '../models/city_runner_models.dart';
import '../repositories/city_runner_repository.dart';
import '../services/api_service.dart';
import '../services/token_store.dart';

class AppProvider extends ChangeNotifier {
  AppProvider(this._repository, {TokenStore? tokenStore}) : _tokenStore = tokenStore ?? TokenStore();

  final CityRunnerRepository _repository;
  final TokenStore _tokenStore;

  List<BusState> publicBuses = const [];
  DriverDashboard? driverDashboard;
  AdminOverview? adminOverview;
  SessionUser? driverUser;
  SessionUser? adminUser;
  UserRole selectedRole = UserRole.passenger;
  int? selectedBusId;
  Coordinate? passengerLocation;
  Coordinate? driverPhoneLocation;
  String? driverToken;
  String? adminToken;
  String? errorMessage;
  String? successMessage;
  UserRole? authRedirectRole;
  bool isLoading = true;
  String? busyAction;

  Timer? _publicTimer;
  Timer? _driverTimer;
  Timer? _adminTimer;
  StreamSubscription<Position>? _driverLocationSubscription;
  DateTime? _lastDriverPush;

  BusState? get selectedBus {
    if (selectedRole == UserRole.driver && driverDashboard?.bus != null) {
      return driverDashboard!.bus;
    }
    final buses = visibleBuses;
    for (final bus in buses) {
      if (bus.id == selectedBusId) return bus;
    }
    return buses.isEmpty ? null : buses.first;
  }

  List<BusState> get visibleBuses {
    if (publicBuses.isNotEmpty) return publicBuses;
    if (adminOverview?.buses.isNotEmpty ?? false) return adminOverview!.buses;
    if (driverDashboard?.bus != null) return [driverDashboard!.bus!];
    return const [];
  }

  double? get distanceToSelectedBus {
    final busPosition = selectedBus?.position;
    if (busPosition == null || passengerLocation == null) return null;
    return haversineDistanceKm(passengerLocation!, busPosition);
  }

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();
    driverToken = await _tokenStore.readDriverToken();
    adminToken = await _tokenStore.readAdminToken();
    await Future.wait([
      refreshPublic(),
      _restoreDriverSession(),
      _restoreAdminSession(),
    ]);
    _startPolling();
    isLoading = false;
    notifyListeners();
  }

Future<bool> login(
  String username,
  String password,
  UserRole role,
) async {
  final success = await _guard('login', () async {
    final result = await _repository.login(
      username.trim(),
      password,
    );

    if (!result.success ||
        result.token == null ||
        result.user == null) {
      throw StateError(result.message);
    }

    if (result.user!.role != role) {
      if (result.token != null) {
        try {
          await _repository.logout(result.token!);
        } catch (_) {}
      }
      throw StateError(
        'These credentials belong to a ${roleToJson(result.user!.role)} account.',
      );
    }

    if (role == UserRole.driver) {
      driverToken = result.token;
      driverUser = result.user;
      selectedRole = UserRole.driver;

      await _tokenStore.saveDriverToken(result.token!);

      await refreshDriver();
      await startDriverLocationStream();
    } else if (role == UserRole.admin) {
      adminToken = result.token;
      adminUser = result.user;
      selectedRole = UserRole.admin;

      await _tokenStore.saveAdminToken(result.token!);

      await refreshAdmin();
    }

    successMessage = result.message;
  });

  return success;
}

  Future<void> refreshPublic() async {
    try {
      publicBuses = await _repository.fetchPublicBuses();
      selectedBusId ??= publicBuses.isEmpty ? null : publicBuses.first.id;
      errorMessage = null;
    } catch (error) {
      errorMessage = _readableError(error);
    }
    notifyListeners();
  }

  Future<void> refreshDriver() async {
    if (driverToken == null) return;
    try {
      driverDashboard = await _repository.fetchDriverDashboard(driverToken!);
      driverUser = driverDashboard!.user;
      selectedBusId = driverDashboard!.bus?.id ?? selectedBusId;
    } catch (error) {
      if (error is ApiUnauthorizedException) {
        await _expireSession(UserRole.driver, error.message);
        return;
      }
      errorMessage = _readableError(error);
    }
    notifyListeners();
  }

  Future<void> refreshAdmin() async {
    if (adminToken == null) return;
    try {
      adminOverview = await _repository.fetchAdminOverview(adminToken!);
      selectedBusId ??= adminOverview!.buses.isEmpty ? null : adminOverview!.buses.first.id;
    } catch (error) {
      if (error is ApiUnauthorizedException) {
        await _expireSession(UserRole.admin, error.message);
        return;
      }
      errorMessage = _readableError(error);
    }
    notifyListeners();
  }

  Future<void> locatePassenger() async {
    await _guard('locate-passenger', () async {
      final position = await _currentPosition();
      passengerLocation = Coordinate(lat: position.latitude, lng: position.longitude);
      successMessage = 'Current location added.';
    });
  }

  Future<void> syncDriverLocationNow() async {
    await _guard('driver-sync', () async {
      if (driverToken == null) throw StateError('Driver login required.');
      final position = await _currentPosition();
      await _pushDriverLocation(position);
      successMessage = 'Live bus location synced from this phone.';
      await Future.wait([refreshPublic(), refreshDriver()]);
    });
  }

  Future<void> startDriverLocationStream() async {
    if (driverToken == null) return;
    await _driverLocationSubscription?.cancel();
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      errorMessage = 'Location services are disabled.';
      notifyListeners();
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      errorMessage = 'Driver GPS permission was denied.';
      notifyListeners();
      return;
    }

    _driverLocationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) async {
      driverPhoneLocation = Coordinate(lat: position.latitude, lng: position.longitude);
      final last = _lastDriverPush;
      if (last != null && DateTime.now().difference(last).inSeconds < 7) {
        notifyListeners();
        return;
      }
      try {
        await _pushDriverLocation(position);
      } catch (error) {
        errorMessage = _readableError(error);
      }
      notifyListeners();
    });
  }

  Future<bool> toggleSeat(int seatId) async {
    return _mutate('seat-$seatId', () => _repository.toggleDriverSeat(driverToken!, seatId));
  }

  Future<bool> resetSeats() async {
    return _mutate('reset-seats', () => _repository.resetDriverSeats(driverToken!));
  }

  Future<bool> toggleBusStatus() async {
    return _mutate('toggle-bus', () => _repository.toggleDriverBus(driverToken!));
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final token = selectedRole == UserRole.driver ? driverToken : adminToken;
    if (token == null) return false;
    return _guard('change-password', () async {
      final result = await _repository.changePassword(token, currentPassword, newPassword);
      if (selectedRole == UserRole.driver && driverUser != null) {
        driverUser = driverUser!.copyWith(mustChangePassword: false);
        if (driverDashboard != null) {
          driverDashboard = DriverDashboard(
            user: driverDashboard!.user.copyWith(mustChangePassword: false),
            bus: driverDashboard!.bus,
          );
        }
      }
      if (selectedRole == UserRole.admin && adminUser != null) {
        adminUser = adminUser!.copyWith(mustChangePassword: false);
      }
      successMessage = result.message;
    });
  }

  Future<bool> createBus(String name, String registrationNumber, String routeName) async {
    return _mutate('create-bus', () => _repository.createBus(adminToken!, name, registrationNumber, routeName));
  }

  Future<bool> createDriver(String username, String displayName, String password, int? assignedBusId) async {
    return _mutate(
      'create-driver',
      () => _repository.createDriver(adminToken!, username, displayName, password, assignedBusId),
    );
  }

  Future<bool> resetDriverPassword(int driverId, String newPassword) async {
    return _mutate('reset-driver-password', () => _repository.resetDriverPassword(adminToken!, driverId, newPassword));
  }

  Future<bool> removeDriver(int driverId, String adminPassword) async {
    return _mutate('remove-driver', () => _repository.removeDriver(adminToken!, driverId, adminPassword));
  }

  Future<void> logout(UserRole role) async {
    if (role == UserRole.driver) {
      final token = driverToken;
      if (token != null) {
        try {
          await _repository.logout(token);
        } catch (_) {}
      }
      await _tokenStore.clearDriverToken();
      await _driverLocationSubscription?.cancel();
      driverToken = null;
      driverUser = null;
      driverDashboard = null;
      if (selectedRole == UserRole.driver) selectedRole = UserRole.passenger;
    } else if (role == UserRole.admin) {
      final token = adminToken;
      if (token != null) {
        try {
          await _repository.logout(token);
        } catch (_) {}
      }
      await _tokenStore.clearAdminToken();
      adminToken = null;
      adminUser = null;
      adminOverview = null;
      if (selectedRole == UserRole.admin) selectedRole = UserRole.passenger;
    }
    successMessage = '${role == UserRole.driver ? 'Driver' : 'Admin'} session cleared.';
    notifyListeners();
  }

  void selectBus(int busId) {
    selectedBusId = busId;
    notifyListeners();
  }

  void selectRole(UserRole role) {
    selectedRole = role;
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  UserRole? consumeAuthRedirect() {
    final role = authRedirectRole;
    authRedirectRole = null;
    return role;
  }

  Future<void> _restoreDriverSession() async {
    if (driverToken == null) return;
    try {
      driverUser = await _repository.fetchCurrentUser(driverToken!);
      await refreshDriver();
      await startDriverLocationStream();
    } catch (_) {
      await _tokenStore.clearDriverToken();
      driverToken = null;
    }
  }

  Future<void> _restoreAdminSession() async {
    if (adminToken == null) return;
    try {
      adminUser = await _repository.fetchCurrentUser(adminToken!);
      await refreshAdmin();
    } catch (_) {
      await _tokenStore.clearAdminToken();
      adminToken = null;
    }
  }

  void _startPolling() {
    _publicTimer?.cancel();
    _driverTimer?.cancel();
    _adminTimer?.cancel();
    _publicTimer = Timer.periodic(const Duration(seconds: AppConstants.publicPollSeconds), (_) => refreshPublic());
    _driverTimer = Timer.periodic(const Duration(seconds: AppConstants.driverPollSeconds), (_) => refreshDriver());
    _adminTimer = Timer.periodic(const Duration(seconds: AppConstants.adminPollSeconds), (_) => refreshAdmin());
  }

  Future<Position> _currentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw StateError('Location services are disabled.');
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was denied.');
    }
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  Future<void> _pushDriverLocation(Position position) async {
    await _repository.updateDriverLocation(driverToken!, position.latitude, position.longitude, position.accuracy);
    _lastDriverPush = DateTime.now();
    driverPhoneLocation = Coordinate(lat: position.latitude, lng: position.longitude);
  }

  Future<bool> _mutate(String action, Future<MutationResult> Function() callback) async {
    return _guard(action, () async {
      final result = await callback();
      successMessage = result.message;
      await Future.wait([refreshPublic(), refreshDriver(), refreshAdmin()]);
    });
  }

  Future<bool> _guard(String action, Future<void> Function() callback) async {
    busyAction = action;
    errorMessage = null;
    notifyListeners();
    try {
      await callback();
      return true;
    } catch (error) {
      if (error is ApiUnauthorizedException) {
        final role = selectedRole == UserRole.admin ? UserRole.admin : UserRole.driver;
        await _expireSession(role, error.message);
        return false;
      }
      errorMessage = _readableError(error);
      return false;
    } finally {
      busyAction = null;
      notifyListeners();
    }
  }

  Future<void> _expireSession(UserRole role, String message) async {
    if (role == UserRole.driver) {
      await _tokenStore.clearDriverToken();
      await _driverLocationSubscription?.cancel();
      driverToken = null;
      driverUser = null;
      driverDashboard = null;
    } else if (role == UserRole.admin) {
      await _tokenStore.clearAdminToken();
      adminToken = null;
      adminUser = null;
      adminOverview = null;
    }
    selectedRole = role;
    authRedirectRole = role;
    errorMessage = message.isEmpty ? 'Session expired. Please log in again.' : message;
    notifyListeners();
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').replaceFirst('Bad state: ', '');
    return message.isEmpty ? 'Request failed.' : message;
  }

  @override
  void dispose() {
    _publicTimer?.cancel();
    _driverTimer?.cancel();
    _adminTimer?.cancel();
    _driverLocationSubscription?.cancel();
    super.dispose();
  }
}
