from __future__ import annotations

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from bus_tracker.models import BusStateResponse, LoginRequest, LoginResponse, MutationResponse
from bus_tracker.state import DISPLAY_FARES, ROUTE_WAYPOINTS, demo_state

app = FastAPI(title="City Runner Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def require_driver(authorization: str | None = Header(default=None)) -> str:
    token = authorization.removeprefix("Bearer ").strip() if authorization else None
    if not demo_state.is_driver_token_valid(token):
        raise HTTPException(status_code=401, detail="Driver login required.")
    return token or ""


@app.get("/api/state", response_model=BusStateResponse)
def get_state() -> BusStateResponse:
    position = demo_state.current_position()
    return BusStateResponse(
        bus_name=demo_state.bus_name,
        is_active=demo_state.is_active,
        current_stop_index=demo_state.current_stop_index(),
        position=position,
        eta_minutes=demo_state.eta_minutes(),
        seats=demo_state.seats,
        route=demo_state.route_points,
        waypoints=ROUTE_WAYPOINTS,
        fare_list=DISPLAY_FARES,
    )


@app.post("/api/auth/login", response_model=LoginResponse)
def login(request: LoginRequest) -> LoginResponse:
    token = demo_state.login(request.username, request.password)
    if token is None:
        return LoginResponse(success=False, message="Invalid driver credentials.")
    return LoginResponse(success=True, token=token, message="Driver access granted.")


@app.post("/api/seats/{seat_id}/toggle", response_model=MutationResponse)
def toggle_seat(seat_id: str, _: str = Depends(require_driver)) -> MutationResponse:
    if not demo_state.toggle_seat(seat_id):
        raise HTTPException(status_code=404, detail="Seat not found.")
    return MutationResponse(success=True, message=f"{seat_id} updated.")


@app.post("/api/seats/reset", response_model=MutationResponse)
def reset_seats(_: str = Depends(require_driver)) -> MutationResponse:
    demo_state.reset_seats()
    return MutationResponse(success=True, message="All seats reset to free.")


@app.post("/api/bus/toggle-active", response_model=MutationResponse)
def toggle_bus(_: str = Depends(require_driver)) -> MutationResponse:
    is_active = demo_state.toggle_bus()
    state_label = "active" if is_active else "inactive"
    return MutationResponse(success=True, message=f"Bus is now {state_label}.")
