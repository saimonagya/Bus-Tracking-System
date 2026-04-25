from __future__ import annotations

from datetime import datetime
import os
from typing import Annotated

from fastapi import Depends, FastAPI, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from bus_tracker.db import Base, SessionLocal, engine
from bus_tracker.entities import AuthSession, Bus, BusStop, Seat, User
from bus_tracker.models import (
    AdminOverviewResponse,
    BusCreateRequest,
    BusResponse,
    ChangePasswordRequest,
    Coordinate,
    DriverCreateRequest,
    DriverDashboardResponse,
    DriverLocationUpdateRequest,
    DriverRemoveRequest,
    DriverPasswordResetRequest,
    DriverSummaryResponse,
    LoginRequest,
    LoginResponse,
    MutationResponse,
    PublicOverviewResponse,
    SeatResponse,
    StopResponse,
    UserSessionResponse,
)
from bus_tracker.security import (
    create_password_record,
    create_session_token,
    hash_session_token,
    verify_password,
)
from bus_tracker.state import (
    DEFAULT_ROUTE_NAME,
    ROUTE_STOPS,
    SEAT_LAYOUT_TEMPLATE,
    default_route_polyline_json,
    estimate_eta_minutes,
    get_current_stop_index,
    location_is_fresh,
    parse_route_polyline,
)


app = FastAPI(title="City Runner Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


DbSession = Annotated[Session, Depends(get_db)]


def create_bus_bundle(db: Session, name: str, registration_number: str, route_name: str = DEFAULT_ROUTE_NAME) -> Bus:
    bus = Bus(
        name=name,
        registration_number=registration_number,
        route_name=route_name,
        route_polyline_json=default_route_polyline_json(),
        seat_capacity=len(SEAT_LAYOUT_TEMPLATE),
        is_active=True,
    )
    db.add(bus)
    db.flush()

    for order_index, stop in enumerate(ROUTE_STOPS):
        db.add(
            BusStop(
                bus_id=bus.id,
                name=stop["name"],
                lat=stop["lat"],
                lng=stop["lng"],
                fare=stop["fare"],
                order_index=order_index,
            )
        )

    for seat_code, label, row_number, column_name in SEAT_LAYOUT_TEMPLATE:
        db.add(
            Seat(
                bus_id=bus.id,
                seat_code=seat_code,
                label=label,
                row_number=row_number,
                column_name=column_name,
                is_booked=False,
            )
        )

    db.flush()
    return bus


def ensure_seed_data() -> None:
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        default_bus = db.scalar(select(Bus).limit(1))
        if default_bus is None:
            create_bus_bundle(db, "City Runner 17", "SK-01-CR-17")
            db.commit()

        admin_exists = db.scalar(select(User).where(User.role == "admin").limit(1))
        admin_username = os.getenv("CITY_RUNNER_ADMIN_USERNAME")
        admin_password = os.getenv("CITY_RUNNER_ADMIN_PASSWORD")
        admin_name = os.getenv("CITY_RUNNER_ADMIN_NAME", "City Runner Admin")
        if admin_exists is None and (not admin_username or not admin_password):
            raise RuntimeError(
                "No admin account exists. Set CITY_RUNNER_ADMIN_USERNAME and "
                "CITY_RUNNER_ADMIN_PASSWORD before starting the backend."
            )

        if admin_exists is None and admin_username and admin_password:
            password_hash, password_salt = create_password_record(admin_password)
            db.add(
                User(
                    username=admin_username,
                    display_name=admin_name,
                    role="admin",
                    password_hash=password_hash,
                    password_salt=password_salt,
                    is_active=True,
                    must_change_password=False,
                )
            )
            db.commit()


@app.on_event("startup")
def on_startup() -> None:
    ensure_seed_data()


def build_user_session(user: User) -> UserSessionResponse:
    return UserSessionResponse(
        id=user.id,
        username=user.username,
        display_name=user.display_name,
        role=user.role,  # type: ignore[arg-type]
        assigned_bus_id=user.assigned_bus_id,
        must_change_password=user.must_change_password,
    )


def build_driver_summary(user: User) -> DriverSummaryResponse:
    assigned_bus_name = user.assigned_bus.name if user.assigned_bus else None
    return DriverSummaryResponse(
        id=user.id,
        username=user.username,
        display_name=user.display_name,
        is_active=user.is_active,
        must_change_password=user.must_change_password,
        assigned_bus_id=user.assigned_bus_id,
        assigned_bus_name=assigned_bus_name,
    )


def build_bus_response(bus: Bus) -> BusResponse:
    route = parse_route_polyline(bus.route_polyline_json)
    stops = [
        StopResponse(
            id=stop.id,
            name=stop.name,
            coordinate=Coordinate(lat=stop.lat, lng=stop.lng),
            fare=stop.fare,
            order_index=stop.order_index,
        )
        for stop in bus.stops
    ]
    seats = [
        SeatResponse(
            id=seat.id,
            seat_code=seat.seat_code,
            label=seat.label,
            row_number=seat.row_number,
            column_name=seat.column_name,
            is_booked=seat.is_booked,
        )
        for seat in bus.seats
    ]
    available_seats = sum(1 for seat in bus.seats if not seat.is_booked)
    assigned_driver = next((driver for driver in bus.drivers if driver.role == "driver"), None)

    current_stop_index = None
    eta_minutes = None
    position = None
    if bus.last_lat is not None and bus.last_lng is not None:
        position = Coordinate(lat=bus.last_lat, lng=bus.last_lng)
        stop_pairs = [(stop.lat, stop.lng) for stop in bus.stops]
        current_stop_index = get_current_stop_index(bus.last_lat, bus.last_lng, stop_pairs)
        destination = bus.stops[-1]
        eta_minutes = estimate_eta_minutes(bus.last_lat, bus.last_lng, destination.lat, destination.lng)

    return BusResponse(
        id=bus.id,
        name=bus.name,
        registration_number=bus.registration_number,
        route_name=bus.route_name,
        seat_capacity=bus.seat_capacity,
        is_active=bus.is_active,
        current_stop_index=current_stop_index,
        eta_minutes=eta_minutes,
        available_seats=available_seats,
        has_live_location=location_is_fresh(bus.location_updated_at),
        location_updated_at=bus.location_updated_at,
        position=position,
        route=route,
        stops=stops,
        seats=seats,
        assigned_driver=build_driver_summary(assigned_driver) if assigned_driver else None,
    )


def get_buses_with_relations(db: Session) -> list[Bus]:
    return list(
        db.scalars(
            select(Bus)
            .options(
                selectinload(Bus.stops),
                selectinload(Bus.seats),
                selectinload(Bus.drivers),
            )
            .order_by(Bus.id)
        )
    )


def require_authenticated_user(
    db: DbSession,
    authorization: Annotated[str | None, Header()] = None,
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required.")

    raw_token = authorization.removeprefix("Bearer ").strip()
    session = db.scalar(
        select(AuthSession)
        .options(selectinload(AuthSession.user).selectinload(User.assigned_bus))
        .where(AuthSession.token_hash == hash_session_token(raw_token))
    )
    if session is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session.")
    if session.expires_at <= datetime.utcnow():
        db.delete(session)
        db.commit()
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Session expired.")
    if not session.user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive account.")
    return session.user


def require_driver(user: Annotated[User, Depends(require_authenticated_user)]) -> User:
    if user.role != "driver":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Driver access required.")
    return user


def require_admin(user: Annotated[User, Depends(require_authenticated_user)]) -> User:
    if user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required.")
    return user


@app.get("/api/public/buses", response_model=PublicOverviewResponse)
def get_public_buses(db: DbSession) -> PublicOverviewResponse:
    buses = [build_bus_response(bus) for bus in get_buses_with_relations(db)]
    return PublicOverviewResponse(buses=buses)


@app.post("/api/auth/login", response_model=LoginResponse)
def login(request: LoginRequest, db: DbSession) -> LoginResponse:
    user = db.scalar(
        select(User)
        .options(selectinload(User.assigned_bus))
        .where(User.username == request.username)
    )
    if user is None or not verify_password(request.password, user.password_salt, user.password_hash):
        return LoginResponse(success=False, message="Invalid username or password.")
    if not user.is_active:
        return LoginResponse(success=False, message="This account is inactive.")

    token, token_hash, expires_at = create_session_token()
    db.add(AuthSession(token_hash=token_hash, user_id=user.id, expires_at=expires_at))
    db.commit()
    db.refresh(user)
    return LoginResponse(
        success=True,
        message="Login successful.",
        token=token,
        user=build_user_session(user),
    )


@app.post("/api/auth/logout", response_model=MutationResponse)
def logout(
    db: DbSession,
    authorization: Annotated[str | None, Header()] = None,
) -> MutationResponse:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required.")

    raw_token = authorization.removeprefix("Bearer ").strip()
    session = db.scalar(select(AuthSession).where(AuthSession.token_hash == hash_session_token(raw_token)))
    if session is not None:
        db.delete(session)
        db.commit()

    return MutationResponse(success=True, message="Session revoked.")


@app.post("/api/auth/change-password", response_model=MutationResponse)
def change_password(
    request: ChangePasswordRequest,
    db: DbSession,
    user: Annotated[User, Depends(require_authenticated_user)],
) -> MutationResponse:
    if not verify_password(request.current_password, user.password_salt, user.password_hash):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Current password is incorrect.")

    password_hash, password_salt = create_password_record(request.new_password)
    user.password_hash = password_hash
    user.password_salt = password_salt
    user.must_change_password = False
    db.add(user)
    db.commit()
    return MutationResponse(success=True, message="Password updated.")


@app.get("/api/auth/me", response_model=UserSessionResponse)
def get_current_session_user(
    user: Annotated[User, Depends(require_authenticated_user)],
) -> UserSessionResponse:
    return build_user_session(user)


@app.get("/api/driver/dashboard", response_model=DriverDashboardResponse)
def driver_dashboard(
    db: DbSession,
    driver: Annotated[User, Depends(require_driver)],
) -> DriverDashboardResponse:
    bus = None
    if driver.assigned_bus_id is not None:
        bus = db.scalar(
            select(Bus)
            .options(
                selectinload(Bus.stops),
                selectinload(Bus.seats),
                selectinload(Bus.drivers),
            )
            .where(Bus.id == driver.assigned_bus_id)
        )
    return DriverDashboardResponse(
        user=build_user_session(driver),
        bus=build_bus_response(bus) if bus else None,
    )


@app.post("/api/driver/location", response_model=MutationResponse)
def update_driver_location(
    request: DriverLocationUpdateRequest,
    db: DbSession,
    driver: Annotated[User, Depends(require_driver)],
) -> MutationResponse:
    if driver.assigned_bus_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No bus is assigned to this driver.")

    bus = db.scalar(select(Bus).where(Bus.id == driver.assigned_bus_id))
    if bus is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assigned bus not found.")

    bus.last_lat = request.lat
    bus.last_lng = request.lng
    bus.last_accuracy_meters = request.accuracy_meters
    bus.location_updated_at = datetime.utcnow()
    db.add(bus)
    db.commit()
    return MutationResponse(success=True, message="Live bus location updated.")


@app.post("/api/driver/seats/{seat_id}/toggle", response_model=MutationResponse)
def toggle_driver_seat(
    seat_id: int,
    db: DbSession,
    driver: Annotated[User, Depends(require_driver)],
) -> MutationResponse:
    if driver.assigned_bus_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No bus is assigned to this driver.")

    seat = db.scalar(select(Seat).where(Seat.id == seat_id, Seat.bus_id == driver.assigned_bus_id))
    if seat is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Seat not found.")

    seat.is_booked = not seat.is_booked
    db.add(seat)
    db.commit()
    return MutationResponse(success=True, message=f"{seat.seat_code} updated.")


@app.post("/api/driver/seats/reset", response_model=MutationResponse)
def reset_driver_seats(
    db: DbSession,
    driver: Annotated[User, Depends(require_driver)],
) -> MutationResponse:
    if driver.assigned_bus_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No bus is assigned to this driver.")

    seats = list(db.scalars(select(Seat).where(Seat.bus_id == driver.assigned_bus_id)))
    for seat in seats:
        seat.is_booked = False
        db.add(seat)
    db.commit()
    return MutationResponse(success=True, message="All seats reset to free.")


@app.post("/api/driver/bus/toggle-active", response_model=MutationResponse)
def toggle_driver_bus_status(
    db: DbSession,
    driver: Annotated[User, Depends(require_driver)],
) -> MutationResponse:
    if driver.assigned_bus_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No bus is assigned to this driver.")

    bus = db.scalar(select(Bus).where(Bus.id == driver.assigned_bus_id))
    if bus is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assigned bus not found.")

    bus.is_active = not bus.is_active
    db.add(bus)
    db.commit()
    return MutationResponse(success=True, message=f"Bus is now {'active' if bus.is_active else 'inactive'}.")


@app.get("/api/admin/overview", response_model=AdminOverviewResponse)
def get_admin_overview(
    db: DbSession,
    _: Annotated[User, Depends(require_admin)],
) -> AdminOverviewResponse:
    buses = [build_bus_response(bus) for bus in get_buses_with_relations(db)]
    drivers = list(
        db.scalars(
            select(User)
            .options(selectinload(User.assigned_bus))
            .where(User.role == "driver")
            .order_by(User.id)
        )
    )
    return AdminOverviewResponse(
        buses=buses,
        drivers=[build_driver_summary(driver) for driver in drivers],
    )


@app.post("/api/admin/buses", response_model=MutationResponse)
def create_bus(
    request: BusCreateRequest,
    db: DbSession,
    _: Annotated[User, Depends(require_admin)],
) -> MutationResponse:
    existing = db.scalar(select(Bus).where(Bus.registration_number == request.registration_number))
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Registration number already exists.")

    create_bus_bundle(db, request.name, request.registration_number, request.route_name)
    db.commit()
    return MutationResponse(success=True, message="New bus added.")


@app.post("/api/admin/drivers", response_model=MutationResponse)
def create_driver(
    request: DriverCreateRequest,
    db: DbSession,
    _: Annotated[User, Depends(require_admin)],
) -> MutationResponse:
    existing = db.scalar(select(User).where(User.username == request.username))
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists.")

    if request.assigned_bus_id is not None:
        bus = db.scalar(select(Bus).where(Bus.id == request.assigned_bus_id))
        if bus is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assigned bus not found.")

    password_hash, password_salt = create_password_record(request.password)
    db.add(
        User(
            username=request.username,
            display_name=request.display_name,
            role="driver",
            password_hash=password_hash,
            password_salt=password_salt,
            is_active=True,
            must_change_password=True,
            assigned_bus_id=request.assigned_bus_id,
        )
    )
    db.commit()
    return MutationResponse(success=True, message="Driver account created.")


@app.post("/api/admin/drivers/{driver_id}/reset-password", response_model=MutationResponse)
def reset_driver_password(
    driver_id: int,
    request: DriverPasswordResetRequest,
    db: DbSession,
    _: Annotated[User, Depends(require_admin)],
) -> MutationResponse:
    driver = db.scalar(select(User).where(User.id == driver_id, User.role == "driver"))
    if driver is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Driver not found.")

    password_hash, password_salt = create_password_record(request.new_password)
    driver.password_hash = password_hash
    driver.password_salt = password_salt
    driver.must_change_password = True
    db.add(driver)
    db.commit()
    return MutationResponse(success=True, message="Driver password reset.")


@app.delete("/api/admin/drivers/{driver_id}", response_model=MutationResponse)
def remove_driver(
    driver_id: int,
    request: DriverRemoveRequest,
    db: DbSession,
    admin: Annotated[User, Depends(require_admin)],
) -> MutationResponse:
    if not verify_password(request.admin_password, admin.password_salt, admin.password_hash):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Admin password is incorrect.")

    driver = db.scalar(select(User).where(User.id == driver_id, User.role == "driver"))
    if driver is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Driver not found.")

    db.delete(driver)
    db.commit()
    return MutationResponse(success=True, message="Driver account removed.")
