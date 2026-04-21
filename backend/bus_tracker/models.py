from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


Role = Literal["admin", "driver"]


class Coordinate(BaseModel):
    lat: float
    lng: float


class StopResponse(BaseModel):
    id: int
    name: str
    coordinate: Coordinate
    fare: int
    order_index: int


class SeatResponse(BaseModel):
    id: int
    seat_code: str
    label: str
    row_number: int
    column_name: str
    is_booked: bool


class DriverSummaryResponse(BaseModel):
    id: int
    username: str
    display_name: str
    is_active: bool
    must_change_password: bool
    assigned_bus_id: int | None
    assigned_bus_name: str | None = None


class BusResponse(BaseModel):
    id: int
    name: str
    registration_number: str
    route_name: str
    seat_capacity: int
    is_active: bool
    current_stop_index: int | None
    eta_minutes: int | None
    available_seats: int
    has_live_location: bool
    location_updated_at: datetime | None
    position: Coordinate | None
    route: list[Coordinate]
    stops: list[StopResponse]
    seats: list[SeatResponse]
    assigned_driver: DriverSummaryResponse | None = None


class PublicOverviewResponse(BaseModel):
    buses: list[BusResponse]


class AdminOverviewResponse(BaseModel):
    buses: list[BusResponse]
    drivers: list[DriverSummaryResponse]


class UserSessionResponse(BaseModel):
    id: int
    username: str
    display_name: str
    role: Role
    assigned_bus_id: int | None
    must_change_password: bool


class DriverDashboardResponse(BaseModel):
    user: UserSessionResponse
    bus: BusResponse | None


class LoginRequest(BaseModel):
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=8, max_length=128)


class LoginResponse(BaseModel):
    success: bool
    message: str
    token: str | None = None
    user: UserSessionResponse | None = None


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=8, max_length=128)
    new_password: str = Field(min_length=8, max_length=128)


class DriverLocationUpdateRequest(BaseModel):
    lat: float
    lng: float
    accuracy_meters: float | None = None


class BusCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    registration_number: str = Field(min_length=2, max_length=32)
    route_name: str = Field(default="Gangtok → Ranipool", min_length=3, max_length=120)


class DriverCreateRequest(BaseModel):
    username: str = Field(min_length=3, max_length=64)
    display_name: str = Field(min_length=2, max_length=120)
    password: str = Field(min_length=8, max_length=128)
    assigned_bus_id: int | None = None


class DriverPasswordResetRequest(BaseModel):
    new_password: str = Field(min_length=8, max_length=128)


class DriverRemoveRequest(BaseModel):
    admin_password: str = Field(min_length=8, max_length=128)


class MutationResponse(BaseModel):
    success: bool
    message: str
