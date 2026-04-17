export type Coordinate = {
  lat: number;
  lng: number;
};

export type Waypoint = {
  name: string;
  coordinate: Coordinate;
  fare: number;
};

export type Seat = {
  id: string;
  label: string;
  row: number;
  column: string;
  is_booked: boolean;
};

export type BusState = {
  bus_name: string;
  is_active: boolean;
  current_stop_index: number;
  position: Coordinate;
  eta_minutes: number;
  seats: Seat[];
  route: Coordinate[];
  waypoints: Waypoint[];
  fare_list: Waypoint[];
};

export type LoginResponse = {
  success: boolean;
  token?: string | null;
  message: string;
};
