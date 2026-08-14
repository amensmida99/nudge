import { getStoredToken } from "./auth";
import type { Nudge } from "./types";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL;

async function request<T>(path: string, init?: RequestInit, auth = false): Promise<T> {
  if (!API_BASE_URL) {
    throw new Error("NEXT_PUBLIC_API_BASE_URL is not configured");
  }

  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (auth) {
    const token = getStoredToken();
    if (!token) {
      throw new Error("Not signed in");
    }
    headers.Authorization = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: { ...headers, ...init?.headers },
  });

  if (!res.ok) {
    const body = await res.json().catch(() => null);
    throw new Error(body?.error ?? `Request failed with status ${res.status}`);
  }

  if (res.status === 204) {
    return undefined as T;
  }

  return res.json() as Promise<T>;
}

export function register(email: string, password: string): Promise<{ token: string }> {
  return request("/api/auth/register", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
}

export function login(email: string, password: string): Promise<{ token: string }> {
  return request("/api/auth/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
}

export function listNudges(): Promise<Nudge[]> {
  return request("/api/nudges", undefined, true);
}

export interface NudgeInput {
  title: string;
  message: string;
  scheduledAt: string;
}

export function createNudge(input: NudgeInput): Promise<Nudge> {
  return request(
    "/api/nudges",
    {
      method: "POST",
      body: JSON.stringify(input),
    },
    true
  );
}

export function updateNudge(id: string, input: NudgeInput): Promise<Nudge> {
  return request(
    `/api/nudges/${encodeURIComponent(id)}`,
    {
      method: "PUT",
      body: JSON.stringify(input),
    },
    true
  );
}

export function deleteNudge(id: string): Promise<void> {
  return request(`/api/nudges/${encodeURIComponent(id)}`, { method: "DELETE" }, true);
}
