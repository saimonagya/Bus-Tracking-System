import type { BusState, LoginResponse } from "@/lib/types";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

type FetchOptions = RequestInit & {
  token?: string | null;
};

async function request<T>(path: string, options: FetchOptions = {}): Promise<T> {
  const headers = new Headers(options.headers);
  headers.set("Content-Type", "application/json");
  if (options.token) {
    headers.set("Authorization", `Bearer ${options.token}`);
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
    cache: "no-store"
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || "Request failed.");
  }

  return response.json() as Promise<T>;
}

export function fetchBusState(): Promise<BusState> {
  return request<BusState>("/api/state");
}

export function loginDriver(username: string, password: string): Promise<LoginResponse> {
  return request<LoginResponse>("/api/auth/login", {
    method: "POST",
    body: JSON.stringify({ username, password })
  });
}

export function toggleSeat(seatId: string, token: string): Promise<{ success: boolean; message: string }> {
  return request(`/api/seats/${seatId}/toggle`, {
    method: "POST",
    token
  });
}

export function resetSeats(token: string): Promise<{ success: boolean; message: string }> {
  return request("/api/seats/reset", {
    method: "POST",
    token
  });
}

export function toggleBusActive(token: string): Promise<{ success: boolean; message: string }> {
  return request("/api/bus/toggle-active", {
    method: "POST",
    token
  });
}
