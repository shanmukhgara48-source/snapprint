import { useState, type ReactNode } from "react";
import { api } from "./api";
import { AuthContext, type AdminRole, type AuthState } from "./auth";

function decodeJwtRole(token: string): { role: AdminRole; username: string } | null {
  try {
    const base64 = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    const payload = JSON.parse(atob(base64));
    return { role: payload.admin_role, username: payload.sub };
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>(() => {
    const token = sessionStorage.getItem("admin_token");
    const role = sessionStorage.getItem("admin_role") as AdminRole | null;
    const username = sessionStorage.getItem("admin_username");
    return { token, role, username };
  });

  async function login(username: string, password: string) {
    const res = await api.post("/auth/admin/login", { username, password });
    const token: string = res.data.access_token;
    const decoded = decodeJwtRole(token);
    sessionStorage.setItem("admin_token", token);
    if (decoded) {
      sessionStorage.setItem("admin_role", decoded.role);
      sessionStorage.setItem("admin_username", decoded.username);
    }
    setState({ token, role: decoded?.role ?? null, username: decoded?.username ?? username });
  }

  function logout() {
    sessionStorage.removeItem("admin_token");
    sessionStorage.removeItem("admin_role");
    sessionStorage.removeItem("admin_username");
    setState({ token: null, role: null, username: null });
  }

  return (
    <AuthContext.Provider
      value={{ ...state, login, logout, isAuthenticated: !!state.token }}
    >
      {children}
    </AuthContext.Provider>
  );
}
