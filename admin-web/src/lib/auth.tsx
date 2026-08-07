import { createContext, useContext } from "react";

export type AdminRole =
  | "super_admin"
  | "manager"
  | "support_staff"
  | "printing_staff"
  | "delivery_staff";

export interface AuthState {
  token: string | null;
  role: AdminRole | null;
  username: string | null;
}

export interface AuthContextValue extends AuthState {
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
}

export const AuthContext = createContext<AuthContextValue | null>(null);

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
