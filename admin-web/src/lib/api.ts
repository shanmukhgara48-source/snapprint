import axios from "axios";

const apiBaseUrl = import.meta.env.VITE_API_URL;

if (import.meta.env.PROD && !apiBaseUrl) {
  throw new Error("VITE_API_URL must be set for production builds.");
}
if (import.meta.env.PROD && !apiBaseUrl.startsWith("https://")) {
  throw new Error("VITE_API_URL must use HTTPS for production builds.");
}

export const api = axios.create({
  baseURL: apiBaseUrl || "http://localhost:8000",
});

api.interceptors.request.use((config) => {
  const token = sessionStorage.getItem("admin_token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      sessionStorage.removeItem("admin_token");
      sessionStorage.removeItem("admin_role");
      sessionStorage.removeItem("admin_username");
      if (!window.location.pathname.startsWith("/login")) {
        window.location.href = "/login";
      }
    }
    return Promise.reject(error);
  },
);
