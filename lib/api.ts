import type {
  AdminOverview,
  DriverDashboard,
  LoginResponse,
  MutationResponse,
  PublicOverview,
  SessionUser
} from "@/lib/types";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

type FetchOptions = RequestInit & {
  token?: string | null;
};

async function request<T>(path: string, options: FetchOptions = {}): Promise<T> {
  const headers = new Headers(options.headers);
  if (!(options.body instanceof FormData)) {
    headers.set("Content-Type", "application/json");
  }
  if (options.token) {
    headers.set("Authorization", `Bearer ${options.token}`);
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
    cache: "no-store"
  });

  const contentType = response.headers.get("content-type") ?? "";
  const payload = contentType.includes("application/json")
    ? ((await response.json()) as unknown)
    : await response.text();

  if (!response.ok) {
    if (typeof payload === "string") {
      throw new Error(payload || "Request failed.");
    }
    if (
      payload &&
      typeof payload === "object" &&
      "detail" in payload &&
      typeof (payload as { detail?: unknown }).detail === "string"
    ) {
      throw new Error((payload as { detail: string }).detail);
    }
    throw new Error("Request failed.");
  }

  return payload as T;
}

export function fetchPublicBuses(): Promise<PublicOverview> {
  return request<PublicOverview>("/api/public/buses");
}

export function login(username: string, password: string): Promise<LoginResponse> {
  return request<LoginResponse>("/api/auth/login", {
    method: "POST",
    body: JSON.stringify({ username, password })
  });
}

export function fetchCurrentUser(token: string): Promise<SessionUser> {
  return request<SessionUser>("/api/auth/me", { token });
}

export function changePassword(
  token: string,
  currentPassword: string,
  newPassword: string
): Promise<MutationResponse> {
  return request<MutationResponse>("/api/auth/change-password", {
    method: "POST",
    token,
    body: JSON.stringify({
      current_password: currentPassword,
      new_password: newPassword
    })
  });
}

export function fetchDriverDashboard(token: string): Promise<DriverDashboard> {
  return request<DriverDashboard>("/api/driver/dashboard", { token });
}

export function updateDriverLocation(
  token: string,
  lat: number,
  lng: number,
  accuracyMeters?: number
): Promise<MutationResponse> {
  return request<MutationResponse>("/api/driver/location", {
    method: "POST",
    token,
    body: JSON.stringify({
      lat,
      lng,
      accuracy_meters: accuracyMeters ?? null
    })
  });
}

export function toggleDriverSeat(seatId: number, token: string): Promise<MutationResponse> {
  return request<MutationResponse>(`/api/driver/seats/${seatId}/toggle`, {
    method: "POST",
    token
  });
}

export function resetDriverSeats(token: string): Promise<MutationResponse> {
  return request<MutationResponse>("/api/driver/seats/reset", {
    method: "POST",
    token
  });
}

export function toggleDriverBus(token: string): Promise<MutationResponse> {
  return request<MutationResponse>("/api/driver/bus/toggle-active", {
    method: "POST",
    token
  });
}

export function fetchAdminOverview(token: string): Promise<AdminOverview> {
  return request<AdminOverview>("/api/admin/overview", { token });
}

export function createBus(
  token: string,
  payload: {
    name: string;
    registration_number: string;
    route_name: string;
  }
): Promise<MutationResponse> {
  return request<MutationResponse>("/api/admin/buses", {
    method: "POST",
    token,
    body: JSON.stringify(payload)
  });
}

export function createDriver(
  token: string,
  payload: {
    username: string;
    display_name: string;
    password: string;
    assigned_bus_id: number | null;
  }
): Promise<MutationResponse> {
  return request<MutationResponse>("/api/admin/drivers", {
    method: "POST",
    token,
    body: JSON.stringify(payload)
  });
}

export function resetDriverPassword(
  token: string,
  driverId: number,
  newPassword: string
): Promise<MutationResponse> {
  return request<MutationResponse>(`/api/admin/drivers/${driverId}/reset-password`, {
    method: "POST",
    token,
    body: JSON.stringify({ new_password: newPassword })
  });
}

export function removeDriver(
  token: string,
  driverId: number,
  adminPassword: string
): Promise<MutationResponse> {
  return request<MutationResponse>(`/api/admin/drivers/${driverId}`, {
    method: "DELETE",
    token,
    body: JSON.stringify({ admin_password: adminPassword })
  });
}
