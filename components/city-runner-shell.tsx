"use client";

import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import dynamic from "next/dynamic";
import {
  BusFront,
  Crosshair,
  LocateFixed,
  LogOut,
  MapPinned,
  Route,
  UserCog,
  Users
} from "lucide-react";

import {
  changePassword,
  createBus,
  createDriver,
  fetchAdminOverview,
  fetchCurrentUser,
  fetchDriverDashboard,
  fetchPublicBuses,
  login,
  logout,
  removeDriver,
  resetDriverPassword,
  resetDriverSeats,
  toggleDriverBus,
  toggleDriverSeat,
  updateDriverLocation
} from "@/lib/api";
import type {
  AdminOverview,
  BusState,
  Coordinate,
  DriverDashboard,
  MutationResponse,
  Role,
  Seat,
  SessionUser
} from "@/lib/types";

const RouteMap = dynamic(() => import("@/components/route-map").then((mod) => mod.RouteMap), {
  ssr: false,
  loading: () => <div className="h-full w-full animate-pulse bg-slate-900/80" />
});

const DRIVER_TOKEN_KEY = "city-runner-driver-token";
const ADMIN_TOKEN_KEY = "city-runner-admin-token";
const FULL_ROUTE_FARE = 60;

function classNames(...values: Array<string | false | null | undefined>) {
  return values.filter(Boolean).join(" ");
}

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
  return { booked, free: seats.length - booked };
}

function formatLastSeen(value: string | null) {
  if (!value) {
    return "Waiting for driver GPS";
  }
  const timestamp = new Date(value).getTime();
  if (Number.isNaN(timestamp)) {
    return "Waiting for driver GPS";
  }
  const diffMinutes = Math.max(0, Math.round((Date.now() - timestamp) / 60000));
  if (diffMinutes < 1) {
    return "Updated just now";
  }
  if (diffMinutes === 1) {
    return "Updated 1 min ago";
  }
  return `Updated ${diffMinutes} mins ago`;
}

function buildFareList(bus: BusState | null) {
  if (!bus) {
    return [];
  }
  const fares = bus.stops
    .filter((stop) => stop.order_index > 0)
    .map((stop) => ({
      name: stop.name,
      fare: stop.fare
    }));
  return [...fares, { name: "Full Route", fare: FULL_ROUTE_FARE }];
}

export function CityRunnerShell() {
  const [mode, setMode] = useState<"user" | "driver" | "admin">("user");
  const [isBusy, setIsBusy] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [isHydrated, setIsHydrated] = useState(false);
  const [isPublicLoading, setIsPublicLoading] = useState(true);

  const [publicBuses, setPublicBuses] = useState<BusState[]>([]);
  const [driverDashboard, setDriverDashboard] = useState<DriverDashboard | null>(null);
  const [adminOverview, setAdminOverview] = useState<AdminOverview | null>(null);
  const [selectedBusId, setSelectedBusId] = useState<number | null>(null);

  const [driverToken, setDriverToken] = useState<string | null>(null);
  const [adminToken, setAdminToken] = useState<string | null>(null);
  const [driverUser, setDriverUser] = useState<SessionUser | null>(null);
  const [adminUser, setAdminUser] = useState<SessionUser | null>(null);

  const [loginRole, setLoginRole] = useState<Role | null>(null);
  const [loginUsername, setLoginUsername] = useState("");
  const [loginPassword, setLoginPassword] = useState("");

  const [userLocation, setUserLocation] = useState<Coordinate | null>(null);
  const [driverPhoneLocation, setDriverPhoneLocation] = useState<Coordinate | null>(null);
  const [userLocationError, setUserLocationError] = useState<string | null>(null);
  const [driverLocationError, setDriverLocationError] = useState<string | null>(null);

  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");

  const [busName, setBusName] = useState("");
  const [registrationNumber, setRegistrationNumber] = useState("");
  const [routeName, setRouteName] = useState("Gangtok → Ranipool");
  const [driverName, setDriverName] = useState("");
  const [driverUsername, setDriverUsername] = useState("");
  const [driverPassword, setDriverPassword] = useState("");
  const [driverAssignedBusId, setDriverAssignedBusId] = useState<string>("");
  const [resetDriverId, setResetDriverId] = useState<string>("");
  const [resetDriverNewPassword, setResetDriverNewPassword] = useState("");
  const [removeDriverId, setRemoveDriverId] = useState<string>("");
  const [removeDriverAdminPassword, setRemoveDriverAdminPassword] = useState("");

  const lastDriverPushRef = useRef(0);
  const lastSuccessTimeoutRef = useRef<number | null>(null);

  const showSuccess = (message: string) => {
    setSuccessMessage(message);
    if (lastSuccessTimeoutRef.current) {
      window.clearTimeout(lastSuccessTimeoutRef.current);
    }
    lastSuccessTimeoutRef.current = window.setTimeout(() => setSuccessMessage(null), 3500);
  };

  useEffect(() => {
    setIsHydrated(true);
    const storedDriverToken = window.sessionStorage.getItem(DRIVER_TOKEN_KEY);
    const storedAdminToken = window.sessionStorage.getItem(ADMIN_TOKEN_KEY);
    if (storedDriverToken) {
      setDriverToken(storedDriverToken);
      void fetchCurrentUser(storedDriverToken)
        .then(setDriverUser)
        .catch(() => {
          window.sessionStorage.removeItem(DRIVER_TOKEN_KEY);
          setDriverToken(null);
        });
    }
    if (storedAdminToken) {
      setAdminToken(storedAdminToken);
      void fetchCurrentUser(storedAdminToken)
        .then(setAdminUser)
        .catch(() => {
          window.sessionStorage.removeItem(ADMIN_TOKEN_KEY);
          setAdminToken(null);
        });
    }
  }, []);

  useEffect(() => {
    let isMounted = true;

    const loadPublicBuses = async () => {
      try {
        const overview = await fetchPublicBuses();
        if (!isMounted) {
          return;
        }
        setPublicBuses(overview.buses);
        setSelectedBusId((current) => current ?? overview.buses[0]?.id ?? null);
        setIsPublicLoading(false);
      } catch (error) {
        if (isMounted) {
          setErrorMessage(error instanceof Error ? error.message : "Could not load buses.");
          setIsPublicLoading(false);
        }
      }
    };

    void loadPublicBuses();
    const intervalId = window.setInterval(() => {
      void loadPublicBuses();
    }, 8000);

    return () => {
      isMounted = false;
      window.clearInterval(intervalId);
    };
  }, []);

  useEffect(() => {
    if (!driverToken) {
      setDriverDashboard(null);
      setDriverUser(null);
      return;
    }

    let isMounted = true;

    const loadDriver = async () => {
      try {
        const dashboard = await fetchDriverDashboard(driverToken);
        if (!isMounted) {
          return;
        }
        setDriverDashboard(dashboard);
        setDriverUser(dashboard.user);
        if (dashboard.bus) {
          setSelectedBusId(dashboard.bus.id);
        }
      } catch (error) {
        if (isMounted) {
          setErrorMessage(error instanceof Error ? error.message : "Could not load driver dashboard.");
        }
      }
    };

    void loadDriver();
    const intervalId = window.setInterval(() => {
      void loadDriver();
    }, 6000);

    return () => {
      isMounted = false;
      window.clearInterval(intervalId);
    };
  }, [driverToken]);

  useEffect(() => {
    if (!adminToken) {
      setAdminOverview(null);
      setAdminUser(null);
      return;
    }

    let isMounted = true;

    const loadAdmin = async () => {
      try {
        const overview = await fetchAdminOverview(adminToken);
        if (!isMounted) {
          return;
        }
        setAdminOverview(overview);
        setSelectedBusId((current) => current ?? overview.buses[0]?.id ?? null);
      } catch (error) {
        if (isMounted) {
          setErrorMessage(error instanceof Error ? error.message : "Could not load admin overview.");
        }
      }
    };

    void loadAdmin();
    const intervalId = window.setInterval(() => {
      void loadAdmin();
    }, 8000);

    return () => {
      isMounted = false;
      window.clearInterval(intervalId);
    };
  }, [adminToken]);

  useEffect(() => {
    if (!loginRole) {
      return;
    }
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, [loginRole]);

  useEffect(() => {
    if (!driverToken) {
      return;
    }
    if (!navigator.geolocation) {
      setDriverLocationError("Driver device does not support browser geolocation.");
      return;
    }

    const sendLocation = async (coords: GeolocationCoordinates) => {
      const now = Date.now();
      if (now - lastDriverPushRef.current < 7000) {
        return;
      }
      lastDriverPushRef.current = now;
      try {
        await updateDriverLocation(driverToken, coords.latitude, coords.longitude, coords.accuracy);
      } catch (error) {
        setDriverLocationError(error instanceof Error ? error.message : "Could not update live driver location.");
      }
    };

    const watchId = navigator.geolocation.watchPosition(
      (position) => {
        setDriverLocationError(null);
        const coordinate = {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        };
        setDriverPhoneLocation(coordinate);
        void sendLocation(position.coords);
      },
      () => {
        setDriverLocationError("Driver GPS permission was denied.");
      },
      {
        enableHighAccuracy: true,
        maximumAge: 5000,
        timeout: 15000
      }
    );

    return () => navigator.geolocation.clearWatch(watchId);
  }, [driverToken]);

  const mapBuses = useMemo(() => {
    if (publicBuses.length > 0) {
      return publicBuses;
    }
    if (adminOverview?.buses?.length) {
      return adminOverview.buses;
    }
    if (driverDashboard?.bus) {
      return [driverDashboard.bus];
    }
    return [];
  }, [adminOverview?.buses, driverDashboard?.bus, publicBuses]);

  const selectedBus = useMemo(() => {
    if (mode === "driver" && driverDashboard?.bus) {
      return mapBuses.find((bus) => bus.id === driverDashboard.bus?.id) ?? driverDashboard.bus;
    }
    return mapBuses.find((bus) => bus.id === selectedBusId) ?? mapBuses[0] ?? null;
  }, [driverDashboard?.bus, mapBuses, mode, selectedBusId]);

  const seatStats = useMemo(() => getSeatStats(selectedBus?.seats ?? []), [selectedBus?.seats]);
  const busDistance = useMemo(() => {
    if (!selectedBus?.position || !userLocation) {
      return null;
    }
    return haversineDistanceKm(userLocation, selectedBus.position);
  }, [selectedBus?.position, userLocation]);

  const handleOpenProtectedMode = (targetMode: "driver" | "admin") => {
    const token = targetMode === "driver" ? driverToken : adminToken;
    if (token) {
      setMode(targetMode);
      return;
    }
    setLoginRole(targetMode);
    setLoginUsername("");
    setLoginPassword("");
    setErrorMessage(null);
  };

  const handleLogin = async () => {
    if (!loginRole) {
      return;
    }
    setIsBusy("login");
    setErrorMessage(null);
    try {
      const response = await login(loginUsername, loginPassword);
      if (!response.success || !response.token || !response.user) {
        setErrorMessage(response.message);
        return;
      }
      if (response.user.role !== loginRole) {
        setErrorMessage(`These credentials belong to a ${response.user.role} account.`);
        return;
      }

      if (response.user.role === "driver") {
        window.sessionStorage.setItem(DRIVER_TOKEN_KEY, response.token);
        setDriverToken(response.token);
        setDriverUser(response.user);
        setMode("driver");
      } else {
        window.sessionStorage.setItem(ADMIN_TOKEN_KEY, response.token);
        setAdminToken(response.token);
        setAdminUser(response.user);
        setMode("admin");
      }
      setLoginRole(null);
      showSuccess("Signed in successfully.");
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Login failed.");
    } finally {
      setIsBusy(null);
    }
  };

  const handleLocateUser = () => {
    if (!navigator.geolocation) {
      setUserLocationError("Geolocation is not supported on this device.");
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setUserLocationError(null);
        setUserLocation({
          lat: position.coords.latitude,
          lng: position.coords.longitude
        });
      },
      () => {
        setUserLocationError("Location permission was denied.");
      },
      { enableHighAccuracy: true, timeout: 12000 }
    );
  };

  const handleManualDriverSync = () => {
    if (!driverToken) {
      return;
    }
    if (!navigator.geolocation) {
      setDriverLocationError("Driver device does not support browser geolocation.");
      return;
    }
    setIsBusy("driver-sync");
    navigator.geolocation.getCurrentPosition(
      async (position) => {
        try {
          setDriverLocationError(null);
          const coordinate = {
            lat: position.coords.latitude,
            lng: position.coords.longitude
          };
          setDriverPhoneLocation(coordinate);
          await updateDriverLocation(driverToken, coordinate.lat, coordinate.lng, position.coords.accuracy);
          showSuccess("Live bus location synced from this phone.");
        } catch (error) {
          setDriverLocationError(error instanceof Error ? error.message : "Could not sync GPS.");
        } finally {
          setIsBusy(null);
        }
      },
      () => {
        setDriverLocationError("Driver GPS permission was denied.");
        setIsBusy(null);
      },
      { enableHighAccuracy: true, timeout: 12000 }
    );
  };

  const withRefresh = async (action: Promise<MutationResponse>) => {
    const response = await action;
    const [publicOverview, driverView, adminView] = await Promise.all([
      fetchPublicBuses(),
      driverToken ? fetchDriverDashboard(driverToken).catch(() => null) : Promise.resolve(null),
      adminToken ? fetchAdminOverview(adminToken).catch(() => null) : Promise.resolve(null)
    ]);
    setPublicBuses(publicOverview.buses);
    if (driverView) {
      setDriverDashboard(driverView);
      setDriverUser(driverView.user);
    }
    if (adminView) {
      setAdminOverview(adminView);
    }
    showSuccess(response.message);
  };

  const handleToggleSeat = async (seatId: number) => {
    if (!driverToken) {
      handleOpenProtectedMode("driver");
      return;
    }
    setIsBusy(`seat-${seatId}`);
    try {
      await withRefresh(toggleDriverSeat(seatId, driverToken));
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not update seat.");
    } finally {
      setIsBusy(null);
    }
  };

  const handleResetSeats = async () => {
    if (!driverToken) {
      handleOpenProtectedMode("driver");
      return;
    }
    setIsBusy("reset-seats");
    try {
      await withRefresh(resetDriverSeats(driverToken));
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not reset seats.");
    } finally {
      setIsBusy(null);
    }
  };

  const handleToggleBus = async () => {
    if (!driverToken) {
      handleOpenProtectedMode("driver");
      return;
    }
    setIsBusy("toggle-bus");
    try {
      await withRefresh(toggleDriverBus(driverToken));
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not update bus status.");
    } finally {
      setIsBusy(null);
    }
  };

  const handleChangePassword = async () => {
    const token = mode === "driver" ? driverToken : adminToken;
    if (!token) {
      return;
    }
    setIsBusy("change-password");
    try {
      const result = await changePassword(token, currentPassword, newPassword);
      setCurrentPassword("");
      setNewPassword("");
      showSuccess(result.message);
      if (mode === "driver" && driverUser) {
        setDriverUser({ ...driverUser, must_change_password: false });
      }
      if (mode === "admin" && adminUser) {
        setAdminUser({ ...adminUser, must_change_password: false });
      }
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not change password.");
    } finally {
      setIsBusy(null);
    }
  };

  const handleCreateBus = async () => {
    if (!adminToken) {
      handleOpenProtectedMode("admin");
      return;
    }
    setIsBusy("create-bus");
    try {
      await withRefresh(
        createBus(adminToken, {
          name: busName,
          registration_number: registrationNumber,
          route_name: routeName
        })
      );
      setBusName("");
      setRegistrationNumber("");
      setRouteName("Gangtok → Ranipool");
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not add bus.");
    } finally {
      setIsBusy(null);
    }
  };

  const handleCreateDriver = async () => {
    if (!adminToken) {
      handleOpenProtectedMode("admin");
      return;
    }
    setIsBusy("create-driver");
    try {
      await withRefresh(
        createDriver(adminToken, {
          username: driverUsername,
          display_name: driverName,
          password: driverPassword,
          assigned_bus_id: driverAssignedBusId ? Number(driverAssignedBusId) : null
        })
      );
      setDriverName("");
      setDriverUsername("");
      setDriverPassword("");
      setDriverAssignedBusId("");
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not create driver.");
    } finally {
      setIsBusy(null);
    }
  };

  const handleResetDriverPassword = async () => {
    if (!adminToken || !resetDriverId) {
      return;
    }
    setIsBusy("reset-driver-password");
    try {
      await withRefresh(resetDriverPassword(adminToken, Number(resetDriverId), resetDriverNewPassword));
      setResetDriverNewPassword("");
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not reset driver password.");
    } finally {
      setIsBusy(null);
    }
  };

  const handleRemoveDriver = async () => {
    if (!adminToken || !removeDriverId) {
      return;
    }
    setIsBusy("remove-driver");
    try {
      await withRefresh(removeDriver(adminToken, Number(removeDriverId), removeDriverAdminPassword));
      setRemoveDriverId("");
      setRemoveDriverAdminPassword("");
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Could not remove driver.");
    } finally {
      setIsBusy(null);
    }
  };

  const handleLogout = async (role: Role) => {
    const token = role === "driver" ? driverToken : adminToken;
    if (token) {
      try {
        await logout(token);
      } catch {
        // Local session cleanup still happens if the network is unavailable.
      }
    }

    if (role === "driver") {
      window.sessionStorage.removeItem(DRIVER_TOKEN_KEY);
      setDriverToken(null);
      setDriverDashboard(null);
      setDriverUser(null);
      if (mode === "driver") {
        setMode("user");
      }
    } else {
      window.sessionStorage.removeItem(ADMIN_TOKEN_KEY);
      setAdminToken(null);
      setAdminOverview(null);
      setAdminUser(null);
      if (mode === "admin") {
        setMode("user");
      }
    }
    showSuccess(`${role === "driver" ? "Driver" : "Admin"} session revoked.`);
  };

  const activeViewerLocation = mode === "driver" ? driverPhoneLocation : userLocation;
  const activeLocateLabel = mode === "driver" ? "Sync my GPS" : "Locate me";
  const activeViewerLabel = mode === "driver" ? "Driver phone" : "You";
  const sharedMapCard = (
    <EmbeddedMapCard
      buses={mapBuses}
      selectedBusId={selectedBus?.id ?? null}
      viewerLocation={activeViewerLocation}
      viewerLabel={activeViewerLabel}
      locateLabel={activeLocateLabel}
      onLocateViewer={mode === "driver" ? handleManualDriverSync : handleLocateUser}
      onSelectBus={mode === "driver" ? undefined : setSelectedBusId}
    />
  );

  return (
    <main className="min-h-screen bg-transparent text-slate-900">
      <div className="mx-auto flex min-h-screen max-w-7xl flex-col px-4 pb-28 pt-4 sm:px-5 lg:px-6">
        <header className="sticky top-4 z-40">
          <div className="flex items-center justify-between rounded-[28px] border border-white/80 bg-white/92 px-4 py-3 shadow-card backdrop-blur-xl">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.35em] text-accent-600">City Runner</p>
              <h1 className="text-lg font-bold text-slate-900">Live Sikkim bus operations</h1>
            </div>
            <div className="hidden items-center gap-2 md:flex">
              <ModeButton active={mode === "user"} onClick={() => setMode("user")} label="User" />
              <ModeButton active={mode === "driver"} onClick={() => handleOpenProtectedMode("driver")} label="Driver" />
              <ModeButton active={mode === "admin"} onClick={() => handleOpenProtectedMode("admin")} label="Admin" />
            </div>
          </div>
        </header>

        <div className="flex-1 pt-6">
          {!isHydrated || isPublicLoading ? <LoadingShell /> : null}

          {isHydrated && !isPublicLoading && mode === "user" ? (
            <UserPanel
              buses={mapBuses}
              selectedBus={selectedBus}
              selectedBusId={selectedBus?.id ?? null}
              onSelectBus={setSelectedBusId}
              busDistance={busDistance}
              seatStats={seatStats}
              userLocationError={userLocationError}
              embeddedMap={sharedMapCard}
            />
          ) : null}

          {isHydrated && !isPublicLoading && mode === "driver" ? (
            <DriverPanel
              bus={selectedBus}
              driverUser={driverUser}
              driverLocationError={driverLocationError}
              seatStats={seatStats}
              busyAction={isBusy}
              onToggleSeat={handleToggleSeat}
              onResetSeats={handleResetSeats}
              onToggleBus={handleToggleBus}
              onSyncLocation={handleManualDriverSync}
              currentPassword={currentPassword}
              newPassword={newPassword}
              onCurrentPasswordChange={setCurrentPassword}
              onNewPasswordChange={setNewPassword}
              onChangePassword={handleChangePassword}
              onLogout={() => handleLogout("driver")}
              embeddedMap={sharedMapCard}
            />
          ) : null}

          {isHydrated && !isPublicLoading && mode === "admin" ? (
            <AdminPanel
              adminUser={adminUser}
              overview={adminOverview}
              selectedBusId={selectedBus?.id ?? null}
              onSelectBus={setSelectedBusId}
              busName={busName}
              registrationNumber={registrationNumber}
              routeName={routeName}
              driverName={driverName}
              driverUsername={driverUsername}
              driverPassword={driverPassword}
              driverAssignedBusId={driverAssignedBusId}
              resetDriverId={resetDriverId}
              resetDriverNewPassword={resetDriverNewPassword}
              removeDriverId={removeDriverId}
              removeDriverAdminPassword={removeDriverAdminPassword}
              busyAction={isBusy}
              currentPassword={currentPassword}
              newPassword={newPassword}
              onBusNameChange={setBusName}
              onRegistrationNumberChange={setRegistrationNumber}
              onRouteNameChange={setRouteName}
              onDriverNameChange={setDriverName}
              onDriverUsernameChange={setDriverUsername}
              onDriverPasswordChange={setDriverPassword}
              onDriverAssignedBusIdChange={setDriverAssignedBusId}
              onResetDriverIdChange={setResetDriverId}
              onResetDriverNewPasswordChange={setResetDriverNewPassword}
              onRemoveDriverIdChange={setRemoveDriverId}
              onRemoveDriverAdminPasswordChange={setRemoveDriverAdminPassword}
              onCreateBus={handleCreateBus}
              onCreateDriver={handleCreateDriver}
              onResetDriverPassword={handleResetDriverPassword}
              onRemoveDriver={handleRemoveDriver}
              onCurrentPasswordChange={setCurrentPassword}
              onNewPasswordChange={setNewPassword}
              onChangePassword={handleChangePassword}
              onLogout={() => handleLogout("admin")}
              embeddedMap={sharedMapCard}
            />
          ) : null}
        </div>

        <div className="pointer-events-none fixed inset-x-0 bottom-0 z-30 px-6 pb-4 md:hidden">
          <div className="pointer-events-auto mx-auto grid max-w-md grid-cols-3 gap-3 rounded-full border border-white/70 bg-white/90 p-2 shadow-card backdrop-blur-xl">
            <ModeButton active={mode === "user"} onClick={() => setMode("user")} label="User" compact />
            <ModeButton active={mode === "driver"} onClick={() => handleOpenProtectedMode("driver")} label="Driver" compact />
            <ModeButton active={mode === "admin"} onClick={() => handleOpenProtectedMode("admin")} label="Admin" compact />
          </div>
        </div>
      </div>

      {loginRole ? (
        <div className="fixed inset-0 z-[1200] overflow-y-auto bg-slate-950/50 backdrop-blur-sm">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="w-full max-w-md rounded-[28px] bg-white p-6 shadow-panel">
              <p className="text-sm font-semibold uppercase tracking-[0.3em] text-accent-600">{loginRole} login</p>
              <h2 className="mt-2 text-2xl font-bold text-slate-900">Sign in to continue</h2>
              <p className="mt-2 text-sm leading-6 text-slate-500">
                {loginRole === "driver"
                  ? "Use your assigned driver account. This device will become the live GPS source for the bus."
                  : "Use your admin account to manage buses, drivers, and credentials."}
              </p>
              <div className="mt-5 space-y-4">
                <Field label="Username" value={loginUsername} onChange={setLoginUsername} />
                <Field label="Password" type="password" value={loginPassword} onChange={setLoginPassword} />
              </div>
              {errorMessage ? (
                <p className="mt-3 rounded-2xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{errorMessage}</p>
              ) : null}
              <div className="mt-5 flex gap-3">
                <button
                  type="button"
                  onClick={() => setLoginRole(null)}
                  className="flex-1 rounded-2xl border border-slate-200 px-4 py-3 font-semibold text-slate-700"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={handleLogin}
                  disabled={isBusy === "login"}
                  className="flex-1 rounded-2xl bg-accent-600 px-4 py-3 font-semibold text-white disabled:opacity-60"
                >
                  {isBusy === "login" ? "Signing in..." : "Login"}
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      {errorMessage && !loginRole ? (
        <Toast tone="error" message={errorMessage} onDismiss={() => setErrorMessage(null)} />
      ) : null}
      {successMessage ? <Toast tone="success" message={successMessage} onDismiss={() => setSuccessMessage(null)} /> : null}
    </main>
  );
}

function UserPanel({
  buses,
  selectedBus,
  selectedBusId,
  onSelectBus,
  busDistance,
  seatStats,
  userLocationError,
  embeddedMap
}: {
  buses: BusState[];
  selectedBus: BusState | null;
  selectedBusId: number | null;
  onSelectBus: (busId: number) => void;
  busDistance: number | null;
  seatStats: { free: number; booked: number };
  userLocationError: string | null;
  embeddedMap: ReactNode;
}) {
  const fareList = buildFareList(selectedBus);

  return (
    <div className="grid gap-4 lg:grid-cols-[1.25fr_0.95fr]">
      <div className="space-y-4">
        <div className="rounded-[26px] bg-white p-5 shadow-card">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.28em] text-accent-600">Passenger view</p>
              <h2 className="mt-1 text-2xl font-bold text-slate-900">{selectedBus?.name ?? "No buses found"}</h2>
              <p className="mt-2 text-sm text-slate-500">
                {selectedBus?.route_name ?? "No route available"}
              </p>
            </div>
            <StatusPill active={selectedBus?.is_active ?? false} live={selectedBus?.has_live_location ?? false} />
          </div>

          <div className="mt-4 grid gap-3 sm:grid-cols-3">
            <StatCard label="Distance to bus" value={busDistance !== null ? `${busDistance.toFixed(1)} km` : "Enable GPS"} icon={<LocateFixed className="h-4 w-4 text-accent-600" />} />
            <StatCard label="ETA" value={selectedBus?.eta_minutes ? `${selectedBus.eta_minutes} min` : "GPS pending"} icon={<Route className="h-4 w-4 text-accent-600" />} />
            <StatCard label="Seats available" value={`${seatStats.free} free`} icon={<BusFront className="h-4 w-4 text-accent-600" />} />
          </div>

          <div className="mt-4 rounded-[22px] border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-600">
            {userLocationError ?? formatLastSeen(selectedBus?.location_updated_at ?? null)}
          </div>
        </div>

        <BusSelector buses={buses} selectedBusId={selectedBusId} onSelectBus={onSelectBus} />
        {embeddedMap}

        <div className="grid gap-4 xl:grid-cols-[0.95fr_1.05fr]">
          <FareCard fareList={fareList} />
          <SeatCard
            seats={selectedBus?.seats ?? []}
            readOnly
            busyAction={null}
            onToggleSeat={() => undefined}
            freeCount={seatStats.free}
            bookedCount={seatStats.booked}
          />
        </div>
      </div>

      <div className="space-y-4">
        <StopsCard bus={selectedBus} />
        <InfoStack
          title="Route notes"
          items={[
            ["Tracking source", "Live GPS from driver phone"],
            ["Selected bus", selectedBus?.registration_number ?? "Unavailable"],
            ["Driver", selectedBus?.assigned_driver?.display_name ?? "Not assigned"],
            ["Map accuracy", "Based on browser location permissions"]
          ]}
        />
      </div>
    </div>
  );
}

function DriverPanel({
  bus,
  driverUser,
  driverLocationError,
  seatStats,
  busyAction,
  onToggleSeat,
  onResetSeats,
  onToggleBus,
  onSyncLocation,
  currentPassword,
  newPassword,
  onCurrentPasswordChange,
  onNewPasswordChange,
  onChangePassword,
  onLogout,
  embeddedMap
}: {
  bus: BusState | null;
  driverUser: SessionUser | null;
  driverLocationError: string | null;
  seatStats: { free: number; booked: number };
  busyAction: string | null;
  onToggleSeat: (seatId: number) => void;
  onResetSeats: () => void;
  onToggleBus: () => void;
  onSyncLocation: () => void;
  currentPassword: string;
  newPassword: string;
  onCurrentPasswordChange: (value: string) => void;
  onNewPasswordChange: (value: string) => void;
  onChangePassword: () => void;
  onLogout: () => void;
  embeddedMap: ReactNode;
}) {
  const fareList = buildFareList(bus);

  return (
    <div className="grid gap-4 lg:grid-cols-[1.25fr_0.95fr]">
      <div className="space-y-4">
        <div className="rounded-[26px] bg-white p-5 shadow-card">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.28em] text-accent-600">Driver control</p>
              <h2 className="mt-1 text-2xl font-bold text-slate-900">{bus?.name ?? "No bus assigned"}</h2>
              <p className="mt-2 text-sm text-slate-500">
                {driverUser ? `${driverUser.display_name} • ${driverUser.username}` : "Driver session inactive"}
              </p>
            </div>
            <div className="flex items-center gap-2">
              {driverUser?.must_change_password ? (
                <span className="rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-amber-700">
                  Password change required
                </span>
              ) : null}
              <button
                type="button"
                onClick={onLogout}
                className="inline-flex items-center gap-2 rounded-full bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-700"
              >
                <LogOut className="h-4 w-4" />
                Logout
              </button>
            </div>
          </div>

          <div className="mt-4 grid gap-3 sm:grid-cols-3">
            <StatCard label="GPS status" value={bus?.has_live_location ? "Sharing" : "Waiting"} icon={<Crosshair className="h-4 w-4 text-accent-600" />} />
            <StatCard label="Seats available" value={`${seatStats.free} free`} icon={<Users className="h-4 w-4 text-accent-600" />} />
            <StatCard label="ETA to Ranipool" value={bus?.eta_minutes ? `${bus.eta_minutes} min` : "GPS pending"} icon={<Route className="h-4 w-4 text-accent-600" />} />
          </div>

          <div className="mt-4 flex flex-wrap gap-3">
            <ActionButton label="Sync GPS now" onClick={onSyncLocation} busy={busyAction === "driver-sync"} />
            <ActionButton label={bus?.is_active ? "Set bus inactive" : "Set bus active"} onClick={onToggleBus} busy={busyAction === "toggle-bus"} inverse />
            <ActionButton label="Reset all seats" onClick={onResetSeats} busy={busyAction === "reset-seats"} subtle />
          </div>

          <div className="mt-4 rounded-[22px] border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-600">
            {driverLocationError ?? formatLastSeen(bus?.location_updated_at ?? null)}
          </div>
        </div>
        {embeddedMap}

        <div className="grid gap-4 xl:grid-cols-[0.95fr_1.05fr]">
          <FareCard fareList={fareList} />
          <SeatCard
            seats={bus?.seats ?? []}
            readOnly={false}
            busyAction={busyAction}
            onToggleSeat={onToggleSeat}
            freeCount={seatStats.free}
            bookedCount={seatStats.booked}
          />
        </div>
      </div>

      <div className="space-y-4">
        <StopsCard bus={bus} />
        <PasswordCard
          title="Change your password"
          subtitle="Drivers can rotate their own password after admin onboarding."
          currentPassword={currentPassword}
          newPassword={newPassword}
          onCurrentPasswordChange={onCurrentPasswordChange}
          onNewPasswordChange={onNewPasswordChange}
          onSubmit={onChangePassword}
          busy={busyAction === "change-password"}
        />
      </div>
    </div>
  );
}

function AdminPanel({
  adminUser,
  overview,
  selectedBusId,
  onSelectBus,
  busName,
  registrationNumber,
  routeName,
  driverName,
  driverUsername,
  driverPassword,
  driverAssignedBusId,
  resetDriverId,
  resetDriverNewPassword,
  removeDriverId,
  removeDriverAdminPassword,
  busyAction,
  currentPassword,
  newPassword,
  onBusNameChange,
  onRegistrationNumberChange,
  onRouteNameChange,
  onDriverNameChange,
  onDriverUsernameChange,
  onDriverPasswordChange,
  onDriverAssignedBusIdChange,
  onResetDriverIdChange,
  onResetDriverNewPasswordChange,
  onRemoveDriverIdChange,
  onRemoveDriverAdminPasswordChange,
  onCreateBus,
  onCreateDriver,
  onResetDriverPassword,
  onRemoveDriver,
  onCurrentPasswordChange,
  onNewPasswordChange,
  onChangePassword,
  onLogout,
  embeddedMap
}: {
  adminUser: SessionUser | null;
  overview: AdminOverview | null;
  selectedBusId: number | null;
  onSelectBus: (busId: number) => void;
  busName: string;
  registrationNumber: string;
  routeName: string;
  driverName: string;
  driverUsername: string;
  driverPassword: string;
  driverAssignedBusId: string;
  resetDriverId: string;
  resetDriverNewPassword: string;
  removeDriverId: string;
  removeDriverAdminPassword: string;
  busyAction: string | null;
  currentPassword: string;
  newPassword: string;
  onBusNameChange: (value: string) => void;
  onRegistrationNumberChange: (value: string) => void;
  onRouteNameChange: (value: string) => void;
  onDriverNameChange: (value: string) => void;
  onDriverUsernameChange: (value: string) => void;
  onDriverPasswordChange: (value: string) => void;
  onDriverAssignedBusIdChange: (value: string) => void;
  onResetDriverIdChange: (value: string) => void;
  onResetDriverNewPasswordChange: (value: string) => void;
  onRemoveDriverIdChange: (value: string) => void;
  onRemoveDriverAdminPasswordChange: (value: string) => void;
  onCreateBus: () => void;
  onCreateDriver: () => void;
  onResetDriverPassword: () => void;
  onRemoveDriver: () => void;
  onCurrentPasswordChange: (value: string) => void;
  onNewPasswordChange: (value: string) => void;
  onChangePassword: () => void;
  onLogout: () => void;
  embeddedMap: ReactNode;
}) {
  return (
    <div className="grid gap-4 lg:grid-cols-[1.2fr_1fr]">
      <div className="space-y-4">
        <div className="rounded-[26px] bg-white p-5 shadow-card">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.28em] text-accent-600">Admin operations</p>
              <h2 className="mt-1 text-2xl font-bold text-slate-900">{adminUser?.display_name ?? "Admin panel"}</h2>
              <p className="mt-2 text-sm text-slate-500">
                Add buses, provision drivers, and monitor live bus locations from one place.
              </p>
            </div>
            <button
              type="button"
              onClick={onLogout}
              className="inline-flex items-center gap-2 rounded-full bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-700"
            >
              <LogOut className="h-4 w-4" />
              Logout
            </button>
          </div>

          <div className="mt-4 grid gap-3 sm:grid-cols-3">
            <StatCard label="Total buses" value={`${overview?.buses.length ?? 0}`} icon={<BusFront className="h-4 w-4 text-accent-600" />} />
            <StatCard label="Driver accounts" value={`${overview?.drivers.length ?? 0}`} icon={<UserCog className="h-4 w-4 text-accent-600" />} />
            <StatCard label="Live buses" value={`${overview?.buses.filter((bus) => bus.has_live_location).length ?? 0}`} icon={<MapPinned className="h-4 w-4 text-accent-600" />} />
          </div>
        </div>

        <BusSelector buses={overview?.buses ?? []} selectedBusId={selectedBusId} onSelectBus={onSelectBus} />
        {embeddedMap}

        <div className="grid gap-4 xl:grid-cols-2">
          <FormCard
            title="Add a bus"
            subtitle="Each new bus gets the Gangtok → Ranipool stops and 17-seat layout."
            actionLabel="Create bus"
            busy={busyAction === "create-bus"}
            onSubmit={onCreateBus}
          >
            <Field label="Bus name" value={busName} onChange={onBusNameChange} placeholder="City Runner 18" />
            <Field label="Registration number" value={registrationNumber} onChange={onRegistrationNumberChange} placeholder="SK-01-CR-18" />
            <Field label="Route name" value={routeName} onChange={onRouteNameChange} />
          </FormCard>

          <FormCard
            title="Create driver login"
            subtitle="Admin chooses the initial credentials. Driver should change the password after first login."
            actionLabel="Create driver"
            busy={busyAction === "create-driver"}
            onSubmit={onCreateDriver}
          >
            <Field label="Driver name" value={driverName} onChange={onDriverNameChange} placeholder="Aman Rai" />
            <Field label="Username" value={driverUsername} onChange={onDriverUsernameChange} placeholder="aman.rai" />
            <Field label="Initial password" type="password" value={driverPassword} onChange={onDriverPasswordChange} placeholder="Create a strong password" />
            <SelectField
              label="Assign bus"
              value={driverAssignedBusId}
              onChange={onDriverAssignedBusIdChange}
              options={[
                { label: "No bus yet", value: "" },
                ...(overview?.buses ?? []).map((bus) => ({ label: `${bus.name} • ${bus.registration_number}`, value: String(bus.id) }))
              ]}
            />
          </FormCard>
        </div>
      </div>

      <div className="space-y-4">
        <div className="rounded-[26px] bg-white p-5 shadow-card">
          <div className="flex items-center gap-2 text-slate-500">
            <Users className="h-4 w-4 text-accent-600" />
            <span className="text-sm font-semibold">Driver directory</span>
          </div>
          <div className="mt-4 space-y-3">
            {(overview?.drivers ?? []).map((driver) => (
              <div key={driver.id} className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <p className="font-semibold text-slate-900">{driver.display_name}</p>
                    <p className="text-sm text-slate-500">{driver.username}</p>
                  </div>
                  <span className="rounded-full bg-white px-3 py-1 text-xs font-semibold uppercase tracking-wide text-slate-600">
                    {driver.assigned_bus_name ?? "Unassigned"}
                  </span>
                </div>
                {driver.must_change_password ? (
                  <p className="mt-2 text-xs font-semibold uppercase tracking-wide text-amber-600">Awaiting password change</p>
                ) : null}
              </div>
            ))}
          </div>
        </div>

        <FormCard
          title="Reset a driver password"
          subtitle="Use when a driver forgets their password or changes devices."
          actionLabel="Reset password"
          busy={busyAction === "reset-driver-password"}
          onSubmit={onResetDriverPassword}
        >
          <SelectField
            label="Driver"
            value={resetDriverId}
            onChange={onResetDriverIdChange}
            options={(overview?.drivers ?? []).map((driver) => ({ label: `${driver.display_name} • ${driver.username}`, value: String(driver.id) }))}
          />
          <Field label="New temporary password" type="password" value={resetDriverNewPassword} onChange={onResetDriverNewPasswordChange} placeholder="Set a new temporary password" />
        </FormCard>

        <FormCard
          title="Remove a driver account"
          subtitle="Delete a driver without driver approval. Confirm using your own admin password."
          actionLabel="Remove driver"
          busy={busyAction === "remove-driver"}
          onSubmit={onRemoveDriver}
        >
          <SelectField
            label="Driver"
            value={removeDriverId}
            onChange={onRemoveDriverIdChange}
            options={(overview?.drivers ?? []).map((driver) => ({ label: `${driver.display_name} • ${driver.username}`, value: String(driver.id) }))}
          />
          <Field
            label="Admin password confirmation"
            type="password"
            value={removeDriverAdminPassword}
            onChange={onRemoveDriverAdminPasswordChange}
            placeholder="Enter your admin password"
          />
        </FormCard>

        <PasswordCard
          title="Change admin password"
          subtitle="Admin password rotation uses the same secure hash storage as driver accounts."
          currentPassword={currentPassword}
          newPassword={newPassword}
          onCurrentPasswordChange={onCurrentPasswordChange}
          onNewPasswordChange={onNewPasswordChange}
          onSubmit={onChangePassword}
          busy={busyAction === "change-password"}
        />
      </div>
    </div>
  );
}

function ModeButton({
  active,
  onClick,
  label,
  compact = false
}: {
  active: boolean;
  onClick: () => void;
  label: string;
  compact?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={classNames(
        "rounded-full font-semibold transition",
        compact ? "px-3 py-3 text-sm" : "px-4 py-2 text-sm",
        active ? "bg-accent-600 text-white shadow-lg" : "bg-slate-100 text-slate-700"
      )}
    >
      {label}
    </button>
  );
}

function LoadingShell() {
  return (
    <div className="grid gap-4 lg:grid-cols-[1.25fr_0.95fr]">
      <div className="space-y-4">
        <div className="rounded-[26px] bg-white p-5 shadow-card">
          <div className="h-4 w-40 animate-pulse rounded-full bg-slate-200" />
          <div className="mt-4 h-10 w-72 animate-pulse rounded-2xl bg-slate-200" />
          <div className="mt-3 h-4 w-48 animate-pulse rounded-full bg-slate-100" />
          <div className="mt-5 grid gap-3 sm:grid-cols-3">
            {Array.from({ length: 3 }).map((_, index) => (
              <div key={index} className="rounded-[22px] border border-slate-200 bg-slate-50 p-4">
                <div className="h-10 w-10 animate-pulse rounded-full bg-slate-200" />
                <div className="mt-4 h-6 w-24 animate-pulse rounded-full bg-slate-200" />
                <div className="mt-2 h-3 w-32 animate-pulse rounded-full bg-slate-100" />
              </div>
            ))}
          </div>
        </div>
        <div className="rounded-[26px] bg-white p-5 shadow-card">
          <div className="h-4 w-36 animate-pulse rounded-full bg-slate-200" />
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            {Array.from({ length: 2 }).map((_, index) => (
              <div key={index} className="h-24 animate-pulse rounded-[22px] bg-slate-100" />
            ))}
          </div>
        </div>
        <div className="rounded-[30px] bg-white p-5 shadow-card">
          <div className="h-4 w-28 animate-pulse rounded-full bg-slate-200" />
          <div className="mt-4 h-[320px] animate-pulse rounded-[28px] bg-slate-100" />
        </div>
      </div>

      <div className="space-y-4">
        {Array.from({ length: 2 }).map((_, index) => (
          <div key={index} className="rounded-[26px] bg-white p-5 shadow-card">
            <div className="h-4 w-32 animate-pulse rounded-full bg-slate-200" />
            <div className="mt-4 space-y-3">
              {Array.from({ length: 4 }).map((__, row) => (
                <div key={row} className="h-16 animate-pulse rounded-2xl bg-slate-100" />
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function BusSelector({
  buses,
  selectedBusId,
  onSelectBus
}: {
  buses: BusState[];
  selectedBusId: number | null;
  onSelectBus: (busId: number) => void;
}) {
  return (
    <div className="rounded-[26px] bg-white p-5 shadow-card">
      <div className="flex items-center gap-2 text-slate-500">
        <BusFront className="h-4 w-4 text-accent-600" />
        <span className="text-sm font-semibold">Buses on this route</span>
      </div>
      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        {buses.map((bus) => (
          <button
            key={bus.id}
            type="button"
            onClick={() => onSelectBus(bus.id)}
            className={classNames(
              "rounded-[22px] border px-4 py-4 text-left transition",
              bus.id === selectedBusId ? "border-accent-200 bg-accent-50" : "border-slate-200 bg-slate-50"
            )}
          >
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="font-semibold text-slate-900">{bus.name}</p>
                <p className="text-sm text-slate-500">{bus.registration_number}</p>
              </div>
              <span className={classNames("rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-wide", bus.has_live_location ? "bg-emerald-100 text-emerald-700" : "bg-slate-200 text-slate-600")}>
                {bus.has_live_location ? "Live" : "Idle"}
              </span>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

function EmbeddedMapCard({
  buses,
  selectedBusId,
  viewerLocation,
  viewerLabel,
  locateLabel,
  onLocateViewer,
  onSelectBus
}: {
  buses: BusState[];
  selectedBusId: number | null;
  viewerLocation: Coordinate | null;
  viewerLabel: string;
  locateLabel: string;
  onLocateViewer: () => void;
  onSelectBus?: (busId: number) => void;
}) {
  return (
    <div className="rounded-[30px] bg-white p-5 shadow-card">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-sm font-semibold uppercase tracking-[0.28em] text-accent-600">Live map</p>
          <h3 className="mt-1 text-xl font-bold text-slate-900">Driver GPS on the route</h3>
        </div>
        <div className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-slate-600">
          {buses.filter((bus) => bus.has_live_location).length} live buses
        </div>
      </div>
      <div className="mt-4 overflow-hidden rounded-[28px] border border-slate-200 bg-slate-100 shadow-inner">
        <div className="h-[280px] w-full sm:h-[340px]">
          <RouteMap
            buses={buses}
            selectedBusId={selectedBusId}
            viewerLocation={viewerLocation}
            viewerLabel={viewerLabel}
            locateLabel={locateLabel}
            onLocateViewer={onLocateViewer}
            onSelectBus={onSelectBus}
          />
        </div>
      </div>
    </div>
  );
}

function StopsCard({ bus }: { bus: BusState | null }) {
  return (
    <div className="rounded-[26px] bg-white p-5 shadow-card">
      <div className="flex items-center gap-2 text-slate-500">
        <MapPinned className="h-4 w-4 text-accent-600" />
        <span className="text-sm font-semibold">Sikkim stops</span>
      </div>
      <div className="mt-4 space-y-3">
        {bus?.stops.map((stop, index) => (
          <div
            key={stop.id}
            className={classNames(
              "flex items-center justify-between rounded-2xl border px-4 py-3",
              index === bus.current_stop_index ? "border-accent-200 bg-accent-50" : "border-slate-200 bg-slate-50"
            )}
          >
            <div>
              <p className="font-semibold text-slate-900">{stop.name}</p>
              <p className="text-xs text-slate-500">{index === 0 ? "Origin" : index === bus.stops.length - 1 ? "Destination" : "Waypoint"}</p>
            </div>
            <span className="text-sm font-semibold text-accent-700">{index === 0 ? "Start" : `₹${stop.fare}`}</span>
          </div>
        )) ?? <p className="text-sm text-slate-500">No route loaded.</p>}
      </div>
    </div>
  );
}

function SeatCard({
  seats,
  readOnly,
  busyAction,
  onToggleSeat,
  freeCount,
  bookedCount
}: {
  seats: Seat[];
  readOnly: boolean;
  busyAction: string | null;
  onToggleSeat: (seatId: number) => void;
  freeCount: number;
  bookedCount: number;
}) {
  const frontSeat = seats.find((seat) => seat.row_number === 0);
  const regularRows = Array.from({ length: 6 }, (_, index) => {
    const rowNumber = index + 1;
    return seats.filter((seat) => seat.row_number === rowNumber);
  });
  const rearSeats = seats.filter((seat) => seat.row_number === 7);

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
            <SeatButton seat={frontSeat} readOnly={readOnly} busy={busyAction === `seat-${frontSeat?.id ?? 0}`} onToggleSeat={onToggleSeat} />
          </div>
        </div>

        <div className="space-y-3">
          {regularRows.map((rowSeats, index) => (
            <div key={`row-${index + 1}`} className="grid grid-cols-[1fr_56px_1fr] items-center gap-3">
              <SeatButton seat={rowSeats[0]} readOnly={readOnly} busy={busyAction === `seat-${rowSeats[0]?.id ?? 0}`} onToggleSeat={onToggleSeat} />
              <div className="h-10 rounded-full border border-dashed border-slate-300 bg-white text-center text-xs font-semibold leading-10 text-slate-400">
                Aisle
              </div>
              <SeatButton seat={rowSeats[1]} readOnly={readOnly} busy={busyAction === `seat-${rowSeats[1]?.id ?? 0}`} onToggleSeat={onToggleSeat} />
            </div>
          ))}
        </div>

        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          {rearSeats.map((seat) => (
            <SeatButton key={seat.id} seat={seat} readOnly={readOnly} busy={busyAction === `seat-${seat.id}`} onToggleSeat={onToggleSeat} />
          ))}
        </div>

        <p className="mt-4 text-sm text-slate-500">
          {readOnly ? "Passengers can monitor seat availability only." : "Driver taps directly update the live bus seats."}
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
  onToggleSeat: (seatId: number) => void;
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
        seat.is_booked ? "border-rose-200 bg-rose-500 text-white" : "border-emerald-200 bg-emerald-500 text-white",
        readOnly ? "cursor-default" : "hover:-translate-y-0.5",
        busy ? "opacity-70" : ""
      )}
    >
      <span className="text-xs font-semibold uppercase tracking-[0.22em]">{seat.seat_code}</span>
      <span className="text-sm font-bold">{seat.is_booked ? "Booked" : "Free"}</span>
    </button>
  );
}

function FareCard({ fareList }: { fareList: Array<{ name: string; fare: number }> }) {
  return (
    <div className="rounded-[26px] bg-white p-5 shadow-card">
      <p className="text-sm font-semibold uppercase tracking-[0.28em] text-accent-600">Fare list</p>
      <div className="mt-4 space-y-3">
        {fareList.map((fare) => (
          <div key={`${fare.name}-${fare.fare}`} className="flex items-center justify-between rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
            <span className="font-medium text-slate-700">{fare.name}</span>
            <span className="text-lg font-bold text-accent-700">₹{fare.fare}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function InfoStack({
  title,
  items
}: {
  title: string;
  items: Array<[string, string]>;
}) {
  return (
    <div className="rounded-[26px] bg-white p-5 shadow-card">
      <p className="text-sm font-semibold uppercase tracking-[0.28em] text-accent-600">{title}</p>
      <div className="mt-4 space-y-3">
        {items.map(([label, value]) => (
          <div key={label} className="flex items-center justify-between rounded-2xl bg-slate-50 px-4 py-3">
            <span className="text-sm text-slate-500">{label}</span>
            <span className="text-sm font-semibold text-slate-900">{value}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function PasswordCard({
  title,
  subtitle,
  currentPassword,
  newPassword,
  onCurrentPasswordChange,
  onNewPasswordChange,
  onSubmit,
  busy
}: {
  title: string;
  subtitle: string;
  currentPassword: string;
  newPassword: string;
  onCurrentPasswordChange: (value: string) => void;
  onNewPasswordChange: (value: string) => void;
  onSubmit: () => void;
  busy: boolean;
}) {
  return (
    <FormCard title={title} subtitle={subtitle} actionLabel="Update password" busy={busy} onSubmit={onSubmit}>
      <Field label="Current password" type="password" value={currentPassword} onChange={onCurrentPasswordChange} />
      <Field label="New password" type="password" value={newPassword} onChange={onNewPasswordChange} />
    </FormCard>
  );
}

function FormCard({
  title,
  subtitle,
  actionLabel,
  busy,
  onSubmit,
  children
}: {
  title: string;
  subtitle: string;
  actionLabel: string;
  busy: boolean;
  onSubmit: () => void;
  children: ReactNode;
}) {
  return (
    <div className="rounded-[26px] bg-white p-5 shadow-card">
      <p className="text-sm font-semibold uppercase tracking-[0.28em] text-accent-600">{title}</p>
      <p className="mt-2 text-sm leading-6 text-slate-500">{subtitle}</p>
      <div className="mt-4 space-y-4">{children}</div>
      <button
        type="button"
        onClick={onSubmit}
        disabled={busy}
        className="mt-5 rounded-2xl bg-accent-600 px-4 py-3 text-sm font-semibold text-white disabled:opacity-60"
      >
        {busy ? "Working..." : actionLabel}
      </button>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  type = "text",
  placeholder
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  type?: string;
  placeholder?: string;
}) {
  return (
    <label className="block">
      <span className="mb-2 block text-sm font-semibold text-slate-700">{label}</span>
      <input
        type={type}
        value={value}
        placeholder={placeholder}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none transition focus:border-accent-500 focus:bg-white"
      />
    </label>
  );
}

function SelectField({
  label,
  value,
  onChange,
  options
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  options: Array<{ label: string; value: string }>;
}) {
  return (
    <label className="block">
      <span className="mb-2 block text-sm font-semibold text-slate-700">{label}</span>
      <select
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none transition focus:border-accent-500 focus:bg-white"
      >
        <option value="">Select one</option>
        {options.map((option) => (
          <option key={`${option.label}-${option.value}`} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </label>
  );
}

function ActionButton({
  label,
  onClick,
  busy,
  inverse = false,
  subtle = false
}: {
  label: string;
  onClick: () => void;
  busy: boolean;
  inverse?: boolean;
  subtle?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={busy}
      className={classNames(
        "rounded-2xl px-4 py-3 text-sm font-semibold transition disabled:opacity-60",
        inverse
          ? "bg-slate-900 text-white hover:bg-slate-800"
          : subtle
            ? "border border-slate-200 bg-slate-100 text-slate-700 hover:bg-slate-200"
            : "bg-accent-600 text-white hover:bg-accent-700"
      )}
    >
      {busy ? "Working..." : label}
    </button>
  );
}

function StatCard({
  label,
  value,
  icon
}: {
  label: string;
  value: string;
  icon: ReactNode;
}) {
  return (
    <div className="rounded-[22px] border border-slate-200 bg-slate-50 p-4">
      <div className="mb-3 inline-flex rounded-full bg-white p-2 shadow-sm">{icon}</div>
      <p className="text-lg font-bold text-slate-900">{value}</p>
      <p className="text-xs uppercase tracking-[0.24em] text-slate-500">{label}</p>
    </div>
  );
}

function StatusPill({ active, live }: { active: boolean; live: boolean }) {
  return (
    <div className="flex gap-2">
      <span className={classNames("rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-wide", active ? "bg-emerald-100 text-emerald-700" : "bg-rose-100 text-rose-700")}>
        {active ? "Active" : "Inactive"}
      </span>
      <span className={classNames("rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-wide", live ? "bg-sky-100 text-sky-700" : "bg-slate-200 text-slate-600")}>
        {live ? "GPS live" : "GPS waiting"}
      </span>
    </div>
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

function Toast({
  tone,
  message,
  onDismiss
}: {
  tone: "success" | "error";
  message: string;
  onDismiss: () => void;
}) {
  return (
    <div
      className={classNames(
        "absolute right-4 top-24 z-[1300] max-w-sm rounded-2xl px-4 py-3 text-sm shadow-card",
        tone === "success" ? "bg-emerald-50 text-emerald-700" : "bg-rose-50 text-rose-700"
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <span>{message}</span>
        <button type="button" onClick={onDismiss} className="font-semibold">
          ×
        </button>
      </div>
    </div>
  );
}
