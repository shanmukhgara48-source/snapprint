import { useEffect, useState } from "react";

const ROUTE_EVENT = "snapprint-route-changed";

/** Read a query param from the current URL (the file router only tracks pathname). */
export function readQueryParam(key: string): string {
  try {
    return new URLSearchParams(window.location.search).get(key) ?? "";
  } catch {
    return "";
  }
}

/** Query-param state that follows back/forward + in-app navigation. */
export function useQueryParam(key: string): [string, (v: string) => void] {
  const [value, setValue] = useState(() => readQueryParam(key));
  useEffect(() => {
    const sync = () => setValue(readQueryParam(key));
    window.addEventListener("popstate", sync);
    window.addEventListener(ROUTE_EVENT, sync);
    return () => {
      window.removeEventListener("popstate", sync);
      window.removeEventListener(ROUTE_EVENT, sync);
    };
  }, [key]);
  return [value, setValue];
}
