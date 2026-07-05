import SimpleMockList, { Badge } from "./SimpleMockList";

interface LogRow {
  id: string;
  level: string;
  service: string;
  message: string;
}

const initial: LogRow[] = [
  { id: "1", level: "info", service: "backend", message: "Uvicorn worker started" },
  { id: "2", level: "warn", service: "backend", message: "Razorpay webhook retried once" },
  { id: "3", level: "error", service: "backend", message: "Firebase Storage upload timeout" },
];

export default function SystemLogs() {
  return (
    <SimpleMockList<LogRow>
      title="System Logs"
      subtitle="App-level admin audit trail is real (see Settings → Audit Log) — this is infra/server logs, which aren't shipped anywhere queryable yet"
      columns={[
        { key: "level", label: "Level", render: (r) => <Badge tone={r.level === "error" ? "danger" : r.level === "warn" ? "warning" : "neutral"}>{r.level}</Badge> },
        { key: "service", label: "Service" },
        { key: "message", label: "Message" },
      ]}
      initialRows={initial}
    />
  );
}
