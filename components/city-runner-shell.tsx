"use client";

import { useEffect, useMemo, useState } from "react";
import dynamic from "next/dynamic";
import {
  BusFront,
  LocateFixed,
  LogIn,
  MapPinned,
  Navigation,
  ShieldCheck,
  TimerReset
} from "lucide-react";

import { fetchBusState, loginDriver, resetSeats, toggleBusActive, toggleSeat } from "@/lib/api";
import type { BusState, Coordinate, Seat } from "@/lib/types";

const RouteMap = dynamic(() => import("@/components/route-map").then((mod) => mod.RouteMap), {
  ssr: false,
  loading: () => <div className="h-full w-full animate-pulse bg-slate-900/80" />
});

const DRIVER_TOKEN_KEY = "city-runner-driver-token";

function haversineDistanceKm(pointA: Coordinate, pointB: Coordinate) {
  const toRadians = (value: number) => (value * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRadians(pointB.lat - pointA.lat);
  const dLng = toRadians(pointB.lng - pointA.lng);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(pointA.lat)) *
      Math.cos(toRadians(pointB.lat)) *
      Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

function getSeatStats(seats: Seat[]) {
  const booked = seats.filter((seat) => seat.is_booked).length;
  const free = seats.length - booked;
  return { booked, free };
}

function classNames(...values: Array<string | false | null | undefined>) {
  return values.filter(Boolean).join(" ");
}

export function CityRunnerShell() {
  const [busState, setBusState] = useState<BusState | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isDriverView, setIsDriverView] = useState(false);
  const [isSheetOpen, setIsSheetOpen] = useState(true);
  const [isLoginOpen, setIsLoginOpen] = useState(false);
  const [isBusy, setIsBusy] = useState(false);
  const [username, setUsername] = useState("driver");
  const [password, setPassword] = useState("cityrunner123");
  const [driverToken, setDriverToken] = useState<string | null>(null);
  const [userLocation, setUserLocation] = useState<Coordinate | null>(null);
  const [locateError, setLocateError] = useState<string | null>(null);

  useEffect(() => {
    const existingToken = window.sessionStorage.getItem(DRIVER_TOKEN_KEY);
    if (existingToken) {
      setDriverToken(existingToken);
    }
  }, []);

  useEffect(() => {
    let isMounted = true;

    const loadState = async () => {
      try {
        const state = await fetchBusState();
        if (isMounted) {
          setBusState(state);
        }
      } catch (error) {
        if (isMounted) {
          setErrorMessage(error instanceof Error ? error.message : "Could not load bus data.");
        }
      }
    };

    void loadState();
    const intervalId = window.setInterval(() => {
      void loadState();
    }, 3000);

    return () => {
      isMounted = false;
      window.clearInterval(intervalId);
    };
  }, []);

  const seatStats = useMemo(() => getSeatStats(busState?.seats ?? []), [busState?.seats]);
  const busDistance = useMemo(() => {
    if (!busState || !userLocation) {
      return null;
    }
    return haversineDistanceKm(userLocation, busState.position);
  }, [busState, userLocation]);

  const activeWaypoint = busState?.waypoints[busState.current_stop_index];

  const refreshState = async () => {
    const state = await fetchBusState();
    setBusState(state);
  };

  const handleDriverAccess = () => {
    if (driverToken) {
      setIsDriverView(true);
      setIsSheetOpen(true);
      return;
    }
    setIsLoginOpen(true);
  };

  const handleLogin = async () => {
    setIsBusy(true);
    setErrorMessage(null);
    try {
      const result = await loginDriver(username, password);
      if (!result.success || !result.token) {
        setErrorMessage(result.message);
        return;
      }
      window.sessionStorage.setItem(DRIVER_TOKEN_KEY, result.token);
      setDriverToken(result.token);
      setIsDriverView(true);
      setIsLoginOpen(false);
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Login failed.");
    } finally {
      setIsBusy(false);
    }
  };

  const handleLocateUser = () => {
    if (!navigator.geolocation) {
      setLocateError("Geolocation is not supported on this device.");
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocateError(null);
        setUserLocation({
          lat: position.coords.latitude,
          lng: position.coords.longitude
        });
      },
      () => {
        setLocateError("Location access was denied.");
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  const handleSeatToggle = async (seatId: string) => {
    if (!driverToken) {
      setIsLoginOpen(true);
      return;
    }
    setIsBusy(true);
    try {
      await toggleSeat(seatId, driverToken);
      await refreshState();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not update seat.");
    } finally {
      setIsBusy(false);
    }
  };

  const handleResetSeats = async () => {
    if (!driverToken) {
      setIsLoginOpen(true);
      return;
    }
    setIsBusy(true);
    try {
      await resetSeats(driverToken);
      await refreshState();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not reset seats.");
    } finally {
      setIsBusy(false);
    }
  };

  const handleToggleBus = async () => {
    if (!driverToken) {
      setIsLoginOpen(true);
      return;
    }
    setIsBusy(true);
    try {
      await toggleBusActive(driverToken);
      await refreshState();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not update bus status.");
    } finally {
      setIsBusy(false);
    }
  };

  return (
    <main className="relative min-h-screen overflow-hidden bg-transparent text-slate-900">
      <header className="absolute inset-x-0 top-0 z-[1000] px-4 pt-4">
        <div className="mx-auto flex max-w-6xl items-center justify-between rounded-[28px] border border-white/80 bg-white/92 px-4 py-3 shadow-card backdrop-blur-xl">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.35em] text-accent-600">City Runner</p>
            <h1 className="text-lg font-bold text-slate-900">Gangtok to Ranipool</h1>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setIsDriverView(false)}
              className={classNames(
                "rounded-full px-4 py-2 text-sm font-semibold transition",
                !isDriverView ? "bg-accent-600 text-white shadow-lg" : "bg-slate-100 text-slate-600"
              )}
            >
              User
            </button>
            <button
              type="button"
              onClick={handleDriverAccess}
              className={classNames(
                "rounded-full px-4 py-2 text-sm font-semibold transition",
                isDriverView ? "bg-accent-700 text-white shadow-lg" : "bg-slate-100 text-slate-700"
              )}
            >
              Driver
            </button>
          </div>
        </div>
      </header>

      <section className="absolute inset-0">
        <RouteMap
          busState={busState}
          userLocation={userLocation}
          onLocateUser={handleLocateUser}
        />
      </section>

      <div className="pointer-events-none absolute inset-x-0 bottom-0 z-[1000] px-3 pb-4 sm:px-4">
        <section
          className={classNames(
            "pointer-events-auto mx-auto max-w-6xl overflow-hidden rounded-[30px] border border-white/70 bg-[var(--panel)] shadow-panel backdrop-blur-xl transition-all duration-300",
            isSheetOpen ? "max-h-[78vh]" : "max-h-[112px]"
          )}
        >
          <button
            type="button"
            onClick={() => setIsSheetOpen((value) => !value)}
            className="flex w-full items-center justify-center border-b border-slate-200/80 px-4 py-3"
          >
            <span className="h-1.5 w-14 rounded-full bg-slate-300" />
          </button>

          <div className="max-h-[calc(78vh-56px)] overflow-y-auto px-4 pb-5">
            <div className="grid gap-4 lg:grid-cols-[1.25fr_0.95fr]">
              <div className="space-y-4">
                <div className="rounded-[26px] bg-white p-5 shadow-card">
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div className="space-y-2">
                      <div className="flex items-center gap-2 text-slate-500">
                        <BusFront className="h-4 w-4 text-accent-600" />
                        <span className="text-sm font-medium">Live service overview</span>
                      </div>
                      <h2 className="text-2xl font-bold text-slate-900">{busState?.bus_name ?? "Loading..."}</h2>
                      <div className="flex items-center gap-2">
                        <span
                          className={classNames(
                            "rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-wide",
                            busState?.is_active
                              ? "bg-emerald-100 text-emerald-700"
                              : "bg-rose-100 text-rose-700"
                          )}
                        >
                          {busState?.is_active ? "Active" : "Inactive"}
                        </span>
                        <span className="text-sm text-slate-500">
                          {activeWaypoint ? `Near ${activeWaypoint.name}` : "Fetching route"}
                        </span>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={handleLocateUser}
                      className="inline-flex items-center gap-2 rounded-full bg-accent-50 px-4 py-2 text-sm font-semibold text-accent-700 transition hover:bg-accent-100"
                    >
                      <LocateFixed className="h-4 w-4" />
                      My location
                    </button>
                  </div>

                  <div className="mt-4 grid gap-3 sm:grid-cols-3">
                    <StatCard
                      icon={<Navigation className="h-4 w-4 text-accent-600" />}
                      value={busDistance !== null ? `${busDistance.toFixed(1)} km` : "Enable GPS"}
                      label="Distance to bus"
                    />
                    <StatCard
                      icon={<TimerReset className="h-4 w-4 text-accent-600" />}
                      value={busState ? `${busState.eta_minutes} min` : "--"}
                      label="ETA"
                    />
                    <StatCard
                      icon={<ShieldCheck className="h-4 w-4 text-accent-600" />}
                      value={`${seatStats.free} free`}
                      label="Seats available"
                    />
                  </div>
                </div>

                <div className="grid gap-4 xl:grid-cols-[0.95fr_1.05fr]">
                  <FareCard fares={busState?.fare_list ?? []} />
                  <SeatCard
                    seats={busState?.seats ?? []}
                    readOnly={!isDriverView}
                    busy={isBusy}
                    onToggleSeat={handleSeatToggle}
                    freeCount={seatStats.free}
                    bookedCount={seatStats.booked}
                  />
                </div>
              </div>

              <div className="space-y-4">
                <div className="rounded-[26px] bg-white p-5 shadow-card">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-semibold text-slate-500">Panel mode</p>
                      <h3 className="text-xl font-bold text-slate-900">
                        {isDriverView ? "Driver Control" : "Passenger View"}
                      </h3>
                    </div>
                    <div className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-slate-600">
                      {driverToken ? "Driver unlocked" : "Read only"}
                    </div>
                  </div>

                  <div className="mt-4 space-y-3">
                    <InfoRow label="Current stop" value={activeWaypoint?.name ?? "Loading"} />
                    <InfoRow
                      label="Route coverage"
                      value={`${busState?.waypoints.length ?? 0} key points`}
                    />
                    <InfoRow
                      label="Service status"
                      value={busState?.is_active ? "Visible on map" : "Paused"}
                    />
                    <InfoRow
                      label="Location request"
                      value={locateError ?? (userLocation ? "GPS captured" : "Tap My location")}
                    />
                  </div>
                </div>

                <div className="rounded-[26px] bg-white p-5 shadow-card">
                  <div className="flex items-center gap-2 text-slate-500">
                    <MapPinned className="h-4 w-4 text-accent-600" />
                    <span className="text-sm font-semibold">Stops</span>
                  </div>
                  <div className="mt-4 space-y-3">
                    {busState?.waypoints.map((point, index) => (
                      <div
                        key={point.name}
                        className={classNames(
                          "flex items-center justify-between rounded-2xl border px-4 py-3",
                          index === busState.current_stop_index
                            ? "border-accent-200 bg-accent-50"
                            : "border-slate-200 bg-slate-50"
                        )}
                      >
                        <div>
                          <p className="font-semibold text-slate-900">{point.name}</p>
                          <p className="text-xs text-slate-500">
                            {index === 0 ? "Origin" : index === busState.waypoints.length - 1 ? "Destination" : "Waypoint"}
                          </p>
                        </div>
                        <span className="text-sm font-semibold text-accent-700">
                          {index === 0 ? "Start" : `₹${point.fare}`}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {isDriverView ? (
                  <div className="rounded-[26px] bg-slate-950 p-5 text-white shadow-card">
                    <div className="flex items-center justify-between gap-3">
                      <div>
                        <p className="text-sm font-semibold text-emerald-300">Protected controls</p>
                        <h3 className="text-xl font-bold">Driver actions</h3>
                      </div>
                      <LogIn className="h-5 w-5 text-emerald-300" />
                    </div>
                    <div className="mt-4 grid gap-3">
                      <button
                        type="button"
                        onClick={handleToggleBus}
                        disabled={isBusy}
                        className="rounded-2xl bg-accent-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-accent-700 disabled:opacity-60"
                      >
                        {busState?.is_active ? "Set bus inactive" : "Set bus active"}
                      </button>
                      <button
                        type="button"
                        onClick={handleResetSeats}
                        disabled={isBusy}
                        className="rounded-2xl border border-white/15 bg-white/10 px-4 py-3 text-sm font-semibold text-white transition hover:bg-white/15 disabled:opacity-60"
                      >
                        Reset all seats
                      </button>
                    </div>
                    <p className="mt-4 text-xs text-slate-300">
                      Seat taps are enabled in the layout. Counts update after each action.
                    </p>
                  </div>
                ) : (
                  <div className="rounded-[26px] border border-accent-100 bg-accent-50 p-5 shadow-card">
                    <p className="text-sm font-semibold text-accent-700">Driver access</p>
                    <h3 className="mt-1 text-xl font-bold text-slate-900">Live controls stay protected</h3>
                    <p className="mt-2 text-sm leading-6 text-slate-600">
                      Riders can monitor the route, seat availability, and fares here. Tap the Driver button for the secure seat-management view.
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </section>
      </div>

      <div className="pointer-events-none absolute inset-x-0 bottom-0 z-[1001] px-6 pb-4 md:hidden">
        <div className="pointer-events-auto mx-auto grid max-w-md grid-cols-2 gap-3 rounded-full border border-white/70 bg-white/90 p-2 shadow-card backdrop-blur-xl">
          <button
            type="button"
            onClick={() => setIsDriverView(false)}
            className={classNames(
              "rounded-full px-4 py-3 text-sm font-semibold",
              !isDriverView ? "bg-accent-600 text-white" : "text-slate-600"
            )}
          >
            User
          </button>
          <button
            type="button"
            onClick={handleDriverAccess}
            className={classNames(
              "rounded-full px-4 py-3 text-sm font-semibold",
              isDriverView ? "bg-slate-900 text-white" : "text-slate-700"
            )}
          >
            Driver
          </button>
        </div>
      </div>

      {isLoginOpen ? (
        <div className="absolute inset-0 z-[1200] flex items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-[28px] bg-white p-6 shadow-panel">
            <p className="text-sm font-semibold uppercase tracking-[0.3em] text-accent-600">Driver login</p>
            <h2 className="mt-2 text-2xl font-bold text-slate-900">Unlock seat controls</h2>
            <p className="mt-2 text-sm leading-6 text-slate-500">
              Use the demo credentials to access booking controls and service status updates.
            </p>
            <div className="mt-5 space-y-4">
              <label className="block">
                <span className="mb-2 block text-sm font-semibold text-slate-700">Username</span>
                <input
                  value={username}
                  onChange={(event) => setUsername(event.target.value)}
                  className="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none transition focus:border-accent-500 focus:bg-white"
                />
              </label>
              <label className="block">
                <span className="mb-2 block text-sm font-semibold text-slate-700">Password</span>
                <input
                  type="password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  className="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none transition focus:border-accent-500 focus:bg-white"
                />
              </label>
            </div>
            {errorMessage ? (
              <p className="mt-3 rounded-2xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{errorMessage}</p>
            ) : null}
            <div className="mt-5 flex gap-3">
              <button
                type="button"
                onClick={() => setIsLoginOpen(false)}
                className="flex-1 rounded-2xl border border-slate-200 px-4 py-3 font-semibold text-slate-700"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleLogin}
                disabled={isBusy}
                className="flex-1 rounded-2xl bg-accent-600 px-4 py-3 font-semibold text-white disabled:opacity-60"
              >
                {isBusy ? "Checking..." : "Login"}
              </button>
            </div>
            <p className="mt-4 text-xs text-slate-400">Demo: `driver` / `cityrunner123`</p>
          </div>
        </div>
      ) : null}

      {errorMessage && !isLoginOpen ? (
        <div className="absolute right-4 top-24 z-[1300] max-w-sm rounded-2xl bg-rose-50 px-4 py-3 text-sm text-rose-700 shadow-card">
          {errorMessage}
        </div>
      ) : null}
    </main>
  );
}

function StatCard({
  icon,
  value,
  label
}: {
  icon: React.ReactNode;
  value: string;
  label: string;
}) {
  return (
    <div className="rounded-[22px] border border-slate-200 bg-slate-50 p-4">
      <div className="mb-3 inline-flex rounded-full bg-white p-2 shadow-sm">{icon}</div>
      <p className="text-lg font-bold text-slate-900">{value}</p>
      <p className="text-xs uppercase tracking-[0.24em] text-slate-500">{label}</p>
    </div>
  );
}

function FareCard({ fares }: { fares: BusState["fare_list"] }) {
  return (
    <div className="rounded-[26px] bg-white p-5 shadow-card">
      <p className="text-sm font-semibold uppercase tracking-[0.28em] text-accent-600">Fare list</p>
      <div className="mt-4 space-y-3">
        {fares.map((fare) => (
          <div
            key={`${fare.name}-${fare.fare}`}
            className="flex items-center justify-between rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3"
          >
            <span className="font-medium text-slate-700">{fare.name}</span>
            <span className="text-lg font-bold text-accent-700">₹{fare.fare}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function SeatCard({
  seats,
  readOnly,
  busy,
  freeCount,
  bookedCount,
  onToggleSeat
}: {
  seats: Seat[];
  readOnly: boolean;
  busy: boolean;
  freeCount: number;
  bookedCount: number;
  onToggleSeat: (seatId: string) => void;
}) {
  const frontSeat = seats.find((seat) => seat.row === 0);
  const regularRows = Array.from({ length: 6 }, (_, index) => {
    const rowNumber = index + 1;
    return seats.filter((seat) => seat.row === rowNumber);
  });
  const rearSeats = seats.filter((seat) => seat.row === 7);

  return (
    <div className="rounded-[26px] bg-white p-5 shadow-card">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-sm font-semibold uppercase tracking-[0.28em] text-accent-600">Seat layout</p>
          <h3 className="text-xl font-bold text-slate-900">17-seater arrangement</h3>
        </div>
        <div className="flex gap-2 text-xs font-semibold">
          <LegendChip colorClass="bg-emerald-500" label={`Free ${freeCount}`} />
          <LegendChip colorClass="bg-rose-500" label={`Booked ${bookedCount}`} />
        </div>
      </div>

      <div className="mt-5 rounded-[28px] bg-slate-50 p-4">
        <div className="mb-4 flex items-center justify-between rounded-[22px] bg-slate-900 px-4 py-3 text-white">
          <div>
            <p className="text-xs uppercase tracking-[0.25em] text-slate-400">Front cabin</p>
            <p className="font-semibold">Driver area</p>
          </div>
          <div className="flex items-center gap-4">
            <div className="rounded-2xl bg-white/10 px-4 py-3 text-center">
              <p className="text-[10px] uppercase tracking-[0.22em] text-slate-300">Driver</p>
              <p className="text-sm font-semibold">Wheel</p>
            </div>
            {frontSeat ? (
              <SeatButton seat={frontSeat} readOnly={readOnly} busy={busy} onToggleSeat={onToggleSeat} />
            ) : null}
          </div>
        </div>

        <div className="space-y-3">
          {regularRows.map((rowSeats, rowIndex) => (
            <div key={`row-${rowIndex + 1}`} className="grid grid-cols-[1fr_56px_1fr] items-center gap-3">
              <SeatButton seat={rowSeats[0]} readOnly={readOnly} busy={busy} onToggleSeat={onToggleSeat} />
              <div className="h-10 rounded-full border border-dashed border-slate-300 bg-white text-center text-xs font-semibold leading-10 text-slate-400">
                Aisle
              </div>
              <SeatButton seat={rowSeats[1]} readOnly={readOnly} busy={busy} onToggleSeat={onToggleSeat} />
            </div>
          ))}
        </div>

        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          {rearSeats.map((seat) => (
            <SeatButton key={seat.id} seat={seat} readOnly={readOnly} busy={busy} onToggleSeat={onToggleSeat} />
          ))}
        </div>

        <p className="mt-4 text-sm text-slate-500">
          {readOnly
            ? "Passenger mode keeps the seat map read-only."
            : "Driver mode lets you tap any seat to flip its status."}
        </p>
      </div>
    </div>
  );
}

function SeatButton({
  seat,
  readOnly,
  busy,
  onToggleSeat
}: {
  seat?: Seat;
  readOnly: boolean;
  busy: boolean;
  onToggleSeat: (seatId: string) => void;
}) {
  if (!seat) {
    return <div className="h-16 rounded-2xl border border-dashed border-slate-300 bg-white/60" />;
  }

  return (
    <button
      type="button"
      disabled={readOnly || busy}
      onClick={() => onToggleSeat(seat.id)}
      className={classNames(
        "flex h-16 flex-col items-center justify-center rounded-2xl border text-center transition",
        seat.is_booked
          ? "border-rose-200 bg-rose-500 text-white"
          : "border-emerald-200 bg-emerald-500 text-white",
        readOnly ? "cursor-default" : "hover:-translate-y-0.5",
        busy ? "opacity-70" : ""
      )}
    >
      <span className="text-xs font-semibold uppercase tracking-[0.22em]">{seat.id}</span>
      <span className="text-sm font-bold">{seat.is_booked ? "Booked" : "Free"}</span>
    </button>
  );
}

function LegendChip({ colorClass, label }: { colorClass: string; label: string }) {
  return (
    <div className="inline-flex items-center gap-2 rounded-full bg-slate-100 px-3 py-1.5 text-slate-700">
      <span className={classNames("h-2.5 w-2.5 rounded-full", colorClass)} />
      <span>{label}</span>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between rounded-2xl bg-slate-50 px-4 py-3">
      <span className="text-sm text-slate-500">{label}</span>
      <span className="text-sm font-semibold text-slate-900">{value}</span>
    </div>
  );
}
