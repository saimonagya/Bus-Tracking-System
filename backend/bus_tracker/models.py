from __future__ import annotations

from pydantic import BaseModel


class Coordinate(BaseModel):
    lat: float
    lng: float


class Waypoint(BaseModel):
    name: str
    coordinate: Coordinate
    fare: int


class Seat(BaseModel):
    id: str
    label: str
    row: int
    column: str
    is_booked: bool = False


class BusStateResponse(BaseModel):
    bus_name: str
    is_active: bool
    current_stop_index: int
    position: Coordinate
    eta_minutes: int
    seats: list[Seat]
    route: list[Coordinate]
    waypoints: list[Waypoint]
    fare_list: list[Waypoint]


class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    success: bool
    token: str | None = None
    message: str


class MutationResponse(BaseModel):
    success: bool
    message: str
