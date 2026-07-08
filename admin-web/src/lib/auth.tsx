import { createContext, useContext, useState, type ReactNode } from "react";
import { api } from "./api";

export type AdminRole =
  | "super_admin"
  | "manager"
  | "support_staff"
  | "printing_staff"
  | "delivery_staff";

interface AuthState {
  token: string | null;
  role: AdminRole | null;
  username: string | null;
}

interface AuthContextValue extends AuthState {
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextValue | null>(null);

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
    const token = localStorage.getItem("admin_token");
    const role = localStorage.getItem("admin_role") as AdminRole | null;
    const username = localStorage.getItem("admin_username");
    return { token, role, username };
  });

  async function login(username: string, password: string) {
    const res = await api.post("/auth/admin/login", { username, password });
    const token: string = res.data.access_token;
    const decoded = decodeJwtRole(token);
    localStorage.setItem("admin_token", token);
    if (decoded) {
      localStorage.setItem("admin_role", decoded.role);
      localStorage.setItem("admin_username", decoded.username);
    }
    setState({ token, role: decoded?.role ?? null, username: decoded?.username ?? username });
  }

  function logout() {
    localStorage.removeItem("admin_token");
    localStorage.removeItem("admin_role");
    localStorage.removeItem("admin_username");
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

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
