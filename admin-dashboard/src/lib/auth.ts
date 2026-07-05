export type AdminRole =
  | "super_admin"
  | "manager"
  | "support_staff"
  | "printing_staff"
  | "delivery_staff";

interface JwtPayload {
  sub: string;
  admin_role: AdminRole;
  admin_user_id: string;
  exp: number;
}

function decodeJwt(token: string): JwtPayload | null {
  try {
    const payload = token.split(".")[1];
    const json = atob(payload.replace(/-/g, "+").replace(/_/g, "/"));
    return JSON.parse(json);
  } catch {
    return null;
  }
}

export function saveSession(token: string) {
  const decoded = decodeJwt(token);
  localStorage.setItem("admin_token", token);
  if (decoded) {
    localStorage.setItem("admin_role", decoded.admin_role);
    localStorage.setItem("admin_username", decoded.sub);
  }
}

export function clearSession() {
  localStorage.removeItem("admin_token");
  localStorage.removeItem("admin_role");
  localStorage.removeItem("admin_username");
}

export function getRole(): AdminRole | null {
  if (typeof window === "undefined") return null;
  return (localStorage.getItem("admin_role") as AdminRole) || null;
}

export function getUsername(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("admin_username");
}

export function isLoggedIn(): boolean {
  if (typeof window === "undefined") return false;
  return !!localStorage.getItem("admin_token");
}

export function hasRole(...roles: AdminRole[]): boolean {
  const role = getRole();
  return role !== null && roles.includes(role);
}
