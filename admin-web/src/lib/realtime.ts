import { useEffect } from "react";
import { useQueryClient, type QueryClient } from "@tanstack/react-query";

// Backend event topic -> TanStack Query keys to invalidate.
// Keys match the queryKey prefixes used across src/pages.
const TOPIC_QUERY_KEYS: Record<string, string[]> = {
  product: ["products", "dashboard"],
  category: ["categories", "products"],
  banner: ["banners"],
  coupon: ["coupons"],
  delivery_setting: ["delivery-settings"],
  setting: ["settings"],
  order: ["orders", "order", "dashboard", "dashboard-charts", "analytics-charts"],
  review: ["reviews", "dashboard"],
  payment: ["payments", "dashboard"],
  notification: ["notifications"],
  user: ["users", "user", "delivery-partners"],
};

interface RealtimeEvent {
  type: string;
  topic?: string;
  action?: string;
  entity_id?: string;
}

const realtimeApiBaseUrl = import.meta.env.VITE_API_URL;

if (import.meta.env.PROD && !realtimeApiBaseUrl) {
  throw new Error("VITE_API_URL must be set for production builds.");
}
if (import.meta.env.PROD && !realtimeApiBaseUrl.startsWith("https://")) {
  throw new Error("VITE_API_URL must use HTTPS for production builds.");
}

function wsUrl(): string {
  const base = realtimeApiBaseUrl || "http://localhost:8000";
  return `${base.replace(/^http/, "ws")}/ws/admin`;
}

function invalidateForEvent(queryClient: QueryClient, event: RealtimeEvent) {
  if (event.type !== "event" || !event.topic) return;
  for (const key of TOPIC_QUERY_KEYS[event.topic] ?? []) {
    queryClient.invalidateQueries({ queryKey: [key] });
  }
}

/**
 * Keeps every admin screen live: one authenticated WebSocket to /ws/admin,
 * and each pushed event invalidates the affected query caches so visible
 * pages refetch automatically (edits from other admins, new orders, payment
 * attempts, delivery status changes...).
 *
 * Reconnects with capped exponential backoff; mount once inside Layout.
 */
export function useAdminRealtime() {
  const queryClient = useQueryClient();

  useEffect(() => {
    let ws: WebSocket | null = null;
    let reconnectTimer: number | undefined;
    let heartbeatTimer: number | undefined;
    let retries = 0;
    let closed = false;

    function connect() {
      const token = sessionStorage.getItem("admin_token");
      if (!token || closed) return;

      ws = new WebSocket(wsUrl());

      ws.onopen = () => {
        ws?.send(JSON.stringify({ type: "auth", token }));
        heartbeatTimer = window.setInterval(() => {
          if (ws?.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ type: "ping" }));
          }
        }, 25_000);
      };

      ws.onmessage = (msg) => {
        try {
          const event: RealtimeEvent = JSON.parse(msg.data);
          if (event.type === "auth_ok") retries = 0;
          invalidateForEvent(queryClient, event);
        } catch {
          // ignore malformed frames
        }
      };

      ws.onclose = (e) => {
        window.clearInterval(heartbeatTimer);
        if (closed || e.code === 4401 || e.code === 4403) return; // bad/expired token: stop
        const delay = Math.min(30_000, 1_000 * 2 ** Math.min(retries, 5));
        retries += 1;
        reconnectTimer = window.setTimeout(connect, delay);
      };
    }

    connect();
    return () => {
      closed = true;
      window.clearTimeout(reconnectTimer);
      window.clearInterval(heartbeatTimer);
      ws?.close();
    };
  }, [queryClient]);
}
