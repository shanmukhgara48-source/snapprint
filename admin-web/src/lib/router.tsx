import { useCallback, useSyncExternalStore } from "react";

const routeChanged = "snapprint-route-changed";

function subscribe(listener: () => void) {
  window.addEventListener("popstate", listener);
  window.addEventListener(routeChanged, listener);
  return () => {
    window.removeEventListener("popstate", listener);
    window.removeEventListener(routeChanged, listener);
  };
}

function currentPath() {
  return window.location.pathname;
}

export function navigate(to: string, replace = false) {
  if (!to.startsWith("/") || to.startsWith("//")) return;
  window.history[replace ? "replaceState" : "pushState"](null, "", to);
  window.dispatchEvent(new Event(routeChanged));
}

export function usePathname() {
  return useSyncExternalStore(subscribe, currentPath, () => "/");
}

export function useNavigate() {
  return useCallback((to: string, options?: { replace?: boolean }) => {
    navigate(to, options?.replace);
  }, []);
}

export function routeId(pathname: string, collection: string) {
  const match = pathname.match(new RegExp(`^/${collection}/([^/]+)$`));
  if (!match) return undefined;
  try {
    return decodeURIComponent(match[1]);
  } catch {
    return undefined;
  }
}
