enum UserRole { admin, driver, passenger }

UserRole roleFromJson(String value) {
  return switch (value) {
    'admin' => UserRole.admin,
    'driver' => UserRole.driver,
    _ => UserRole.passenger,
  };
}

String roleToJson(UserRole role) {
  return switch (role) {
    UserRole.admin => 'admin',
    UserRole.driver => 'driver',
    UserRole.passenger => 'passenger',
  };
}

class Coordinate {
  const Coordinate({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory Coordinate.fromJson(Map<String, dynamic> json) => Coordinate(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class Stop {
  const Stop({
    required this.id,
    required this.name,
    required this.coordinate,
    required this.fare,
    required this.orderIndex,
  });

  final int id;
  final String name;
  final Coordinate coordinate;
  final int fare;
  final int orderIndex;

  factory Stop.fromJson(Map<String, dynamic> json) => Stop(
        id: json['id'] as int,
        name: json['name'] as String,
        coordinate: Coordinate.fromJson(json['coordinate'] as Map<String, dynamic>),
        fare: json['fare'] as int,
        orderIndex: json['order_index'] as int,
      );
}

class Seat {
  const Seat({
    required this.id,
    required this.seatCode,
    required this.label,
    required this.rowNumber,
    required this.columnName,
    required this.isBooked,
  });

  final int id;
  final String seatCode;
  final String label;
  final int rowNumber;
  final String columnName;
  final bool isBooked;

  factory Seat.fromJson(Map<String, dynamic> json) => Seat(
        id: json['id'] as int,
        seatCode: json['seat_code'] as String,
        label: json['label'] as String,
        rowNumber: json['row_number'] as int,
        columnName: json['column_name'] as String,
        isBooked: json['is_booked'] as bool,
      );
}

class DriverSummary {
  const DriverSummary({
    required this.id,
    required this.username,
    required this.displayName,
    required this.isActive,
    required this.mustChangePassword,
    required this.assignedBusId,
    this.assignedBusName,
  });

  final int id;
  final String username;
  final String displayName;
  final bool isActive;
  final bool mustChangePassword;
  final int? assignedBusId;
  final String? assignedBusName;

  factory DriverSummary.fromJson(Map<String, dynamic> json) => DriverSummary(
        id: json['id'] as int,
        username: json['username'] as String,
        displayName: json['display_name'] as String,
        isActive: json['is_active'] as bool,
        mustChangePassword: json['must_change_password'] as bool,
        assignedBusId: json['assigned_bus_id'] as int?,
        assignedBusName: json['assigned_bus_name'] as String?,
      );
}

class BusState {
  const BusState({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.routeName,
    required this.seatCapacity,
    required this.isActive,
    required this.currentStopIndex,
    required this.etaMinutes,
    required this.availableSeats,
    required this.hasLiveLocation,
    required this.locationUpdatedAt,
    required this.position,
    required this.route,
    required this.stops,
    required this.seats,
    this.assignedDriver,
  });

  final int id;
  final String name;
  final String registrationNumber;
  final String routeName;
  final int seatCapacity;
  final bool isActive;
  final int? currentStopIndex;
  final int? etaMinutes;
  final int availableSeats;
  final bool hasLiveLocation;
  final DateTime? locationUpdatedAt;
  final Coordinate? position;
  final List<Coordinate> route;
  final List<Stop> stops;
  final List<Seat> seats;
  final DriverSummary? assignedDriver;

  int get bookedSeats => seats.where((seat) => seat.isBooked).length;

  factory BusState.fromJson(Map<String, dynamic> json) => BusState(
        id: json['id'] as int,
        name: json['name'] as String,
        registrationNumber: json['registration_number'] as String,
        routeName: json['route_name'] as String,
        seatCapacity: json['seat_capacity'] as int,
        isActive: json['is_active'] as bool,
        currentStopIndex: json['current_stop_index'] as int?,
        etaMinutes: json['eta_minutes'] as int?,
        availableSeats: json['available_seats'] as int,
        hasLiveLocation: json['has_live_location'] as bool,
        locationUpdatedAt: json['location_updated_at'] == null
            ? null
            : DateTime.parse(json['location_updated_at'] as String),
        position: json['position'] == null
            ? null
            : Coordinate.fromJson(json['position'] as Map<String, dynamic>),
        route: (json['route'] as List<dynamic>)
            .map((item) => Coordinate.fromJson(item as Map<String, dynamic>))
            .toList(),
        stops: (json['stops'] as List<dynamic>)
            .map((item) => Stop.fromJson(item as Map<String, dynamic>))
            .toList(),
        seats: (json['seats'] as List<dynamic>)
            .map((item) => Seat.fromJson(item as Map<String, dynamic>))
            .toList(),
        assignedDriver: json['assigned_driver'] == null
            ? null
            : DriverSummary.fromJson(json['assigned_driver'] as Map<String, dynamic>),
      );
}

class SessionUser {
  const SessionUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.assignedBusId,
    required this.mustChangePassword,
  });

  final int id;
  final String username;
  final String displayName;
  final UserRole role;
  final int? assignedBusId;
  final bool mustChangePassword;

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
        id: json['id'] as int,
        username: json['username'] as String,
        displayName: json['display_name'] as String,
        role: roleFromJson(json['role'] as String),
        assignedBusId: json['assigned_bus_id'] as int?,
        mustChangePassword: json['must_change_password'] as bool,
      );

  SessionUser copyWith({bool? mustChangePassword}) => SessionUser(
        id: id,
        username: username,
        displayName: displayName,
        role: role,
        assignedBusId: assignedBusId,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );
}

class LoginResult {
  const LoginResult({required this.success, required this.message, this.token, this.user});

  final bool success;
  final String message;
  final String? token;
  final SessionUser? user;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        success: json['success'] as bool,
        message: json['message'] as String,
        token: json['token'] as String?,
        user: json['user'] == null ? null : SessionUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class DriverDashboard {
  const DriverDashboard({required this.user, required this.bus});

  final SessionUser user;
  final BusState? bus;

  factory DriverDashboard.fromJson(Map<String, dynamic> json) => DriverDashboard(
        user: SessionUser.fromJson(json['user'] as Map<String, dynamic>),
        bus: json['bus'] == null ? null : BusState.fromJson(json['bus'] as Map<String, dynamic>),
      );
}

class AdminOverview {
  const AdminOverview({required this.buses, required this.drivers});

  final List<BusState> buses;
  final List<DriverSummary> drivers;

  factory AdminOverview.fromJson(Map<String, dynamic> json) => AdminOverview(
        buses: (json['buses'] as List<dynamic>)
            .map((item) => BusState.fromJson(item as Map<String, dynamic>))
            .toList(),
        drivers: (json['drivers'] as List<dynamic>)
            .map((item) => DriverSummary.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class MutationResult {
  const MutationResult({required this.success, required this.message});

  final bool success;
  final String message;

  factory MutationResult.fromJson(Map<String, dynamic> json) => MutationResult(
        success: json['success'] as bool,
        message: json['message'] as String,
      );
}
