export type Role = "admin" | "driver";

export type Coordinate = {
  lat: number;
  lng: number;
};

export type Stop = {
  id: number;
  name: string;
  coordinate: Coordinate;
  fare: number;
  order_index: number;
};

export type Seat = {
  id: number;
  seat_code: string;
  label: string;
  row_number: number;
  column_name: string;
  is_booked: boolean;
};

export type DriverSummary = {
  id: number;
  username: string;
  display_name: string;
  is_active: boolean;
  must_change_password: boolean;
  assigned_bus_id: number | null;
  assigned_bus_name?: string | null;
};

export type BusState = {
  id: number;
  name: string;
  registration_number: string;
  route_name: string;
  seat_capacity: number;
  is_active: boolean;
  current_stop_index: number | null;
  eta_minutes: number | null;
  available_seats: number;
  has_live_location: boolean;
  location_updated_at: string | null;
  position: Coordinate | null;
  route: Coordinate[];
  stops: Stop[];
  seats: Seat[];
  assigned_driver?: DriverSummary | null;
};

export type PublicOverview = {
  buses: BusState[];
};

export type SessionUser = {
  id: number;
  username: string;
  display_name: string;
  role: Role;
  assigned_bus_id: number | null;
  must_change_password: boolean;
};

export type LoginResponse = {
  success: boolean;
  message: string;
  token?: string | null;
  user?: SessionUser | null;
};

export type DriverDashboard = {
  user: SessionUser;
  bus: BusState | null;
};

export type AdminOverview = {
  buses: BusState[];
  drivers: DriverSummary[];
};

export type MutationResponse = {
  success: boolean;
  message: string;
};
