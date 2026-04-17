from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from math import floor
from secrets import token_hex

from .models import Coordinate, Seat, Waypoint


ROUTE_WAYPOINTS = [
    Waypoint(name="Gangtok", coordinate=Coordinate(lat=27.3314, lng=88.6138), fare=0),
    Waypoint(name="Tadong", coordinate=Coordinate(lat=27.3101, lng=88.6004), fare=15),
    Waypoint(name="6th Mile", coordinate=Coordinate(lat=27.2994, lng=88.5947), fare=10),
    Waypoint(name="Boomtar", coordinate=Coordinate(lat=27.2872, lng=88.5875), fare=12),
    Waypoint(name="Singtam Turn", coordinate=Coordinate(lat=27.2785, lng=88.5824), fare=10),
    Waypoint(name="Ranipool", coordinate=Coordinate(lat=27.2698, lng=88.5761), fare=13),
]

DISPLAY_FARES = [
    Waypoint(name="Tadong", coordinate=ROUTE_WAYPOINTS[1].coordinate, fare=15),
    Waypoint(name="6th Mile", coordinate=ROUTE_WAYPOINTS[2].coordinate, fare=10),
    Waypoint(name="Boomtar", coordinate=ROUTE_WAYPOINTS[3].coordinate, fare=12),
    Waypoint(name="Singtam Turn", coordinate=ROUTE_WAYPOINTS[4].coordinate, fare=10),
    Waypoint(name="Ranipool", coordinate=ROUTE_WAYPOINTS[5].coordinate, fare=13),
    Waypoint(name="Full Route", coordinate=ROUTE_WAYPOINTS[5].coordinate, fare=60),
]

SEAT_LAYOUT = [
    Seat(id="S1", label="S1", row=0, column="front", is_booked=False),
    Seat(id="S2", label="S2", row=1, column="left", is_booked=False),
    Seat(id="S3", label="S3", row=1, column="right", is_booked=False),
    Seat(id="S4", label="S4", row=2, column="left", is_booked=False),
    Seat(id="S5", label="S5", row=2, column="right", is_booked=False),
    Seat(id="S6", label="S6", row=3, column="left", is_booked=False),
    Seat(id="S7", label="S7", row=3, column="right", is_booked=False),
    Seat(id="S8", label="S8", row=4, column="left", is_booked=False),
    Seat(id="S9", label="S9", row=4, column="right", is_booked=False),
    Seat(id="S10", label="S10", row=5, column="left", is_booked=False),
    Seat(id="S11", label="S11", row=5, column="right", is_booked=False),
    Seat(id="S12", label="S12", row=6, column="left", is_booked=False),
    Seat(id="S13", label="S13", row=6, column="right", is_booked=False),
    Seat(id="S14", label="S14", row=7, column="rear-1", is_booked=False),
    Seat(id="S15", label="S15", row=7, column="rear-2", is_booked=False),
    Seat(id="S16", label="S16", row=7, column="rear-3", is_booked=False),
    Seat(id="S17", label="S17", row=7, column="rear-4", is_booked=False),
]


def interpolate_route() -> list[Coordinate]:
    segments: list[Coordinate] = []
    for start, end in zip(ROUTE_WAYPOINTS, ROUTE_WAYPOINTS[1:]):
        steps = 10
        for step in range(steps):
            ratio = step / steps
            segments.append(
                Coordinate(
                    lat=start.coordinate.lat + (end.coordinate.lat - start.coordinate.lat) * ratio,
                    lng=start.coordinate.lng + (end.coordinate.lng - start.coordinate.lng) * ratio,
                )
            )
    segments.append(ROUTE_WAYPOINTS[-1].coordinate)
    return segments


ROUTE_POINTS = interpolate_route()


@dataclass
class DemoState:
    bus_name: str = "City Runner 17"
    is_active: bool = True
    seats: list[Seat] = field(default_factory=lambda: [seat.model_copy(deep=True) for seat in SEAT_LAYOUT])
    route_points: list[Coordinate] = field(default_factory=lambda: [point.model_copy(deep=True) for point in ROUTE_POINTS])
    driver_tokens: set[str] = field(default_factory=set)
    progress_index: int = 0
    last_tick: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def tick(self) -> None:
        if not self.is_active:
            self.last_tick = datetime.now(timezone.utc)
            return
        now = datetime.now(timezone.utc)
        elapsed = now - self.last_tick
        step_count = floor(elapsed.total_seconds() / 3)
        if step_count <= 0:
            return
        self.progress_index = min(self.progress_index + step_count, len(self.route_points) - 1)
        self.last_tick = self.last_tick + timedelta(seconds=step_count * 3)

    def current_position(self) -> Coordinate:
        self.tick()
        return self.route_points[self.progress_index]

    def current_stop_index(self) -> int:
        self.tick()
        if self.progress_index >= len(self.route_points) - 1:
            return len(ROUTE_WAYPOINTS) - 1
        segment_length = max(1, len(self.route_points) // (len(ROUTE_WAYPOINTS) - 1))
        return min(self.progress_index // segment_length, len(ROUTE_WAYPOINTS) - 1)

    def eta_minutes(self) -> int:
        self.tick()
        remaining = (len(self.route_points) - 1) - self.progress_index
        return max(1, (remaining * 3) // 60 + 1) if self.is_active else 0

    def toggle_seat(self, seat_id: str) -> bool:
        for seat in self.seats:
            if seat.id == seat_id:
                seat.is_booked = not seat.is_booked
                return True
        return False

    def reset_seats(self) -> None:
        for seat in self.seats:
            seat.is_booked = False

    def toggle_bus(self) -> bool:
        self.tick()
        self.is_active = not self.is_active
        self.last_tick = datetime.now(timezone.utc)
        return self.is_active

    def login(self, username: str, password: str) -> str | None:
        if username == "driver" and password == "cityrunner123":
            token = token_hex(16)
            self.driver_tokens.add(token)
            return token
        return None

    def is_driver_token_valid(self, token: str | None) -> bool:
        return bool(token and token in self.driver_tokens)


demo_state = DemoState()
