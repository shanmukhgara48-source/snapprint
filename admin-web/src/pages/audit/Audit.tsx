import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { AuditLog, LoginHistoryEntry } from "../../lib/types";
import { Badge, Card, EmptyState, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";

export default function Audit() {
  const [tab, setTab] = useState<"audit" | "logins">("audit");

  const audit = useQuery({
    queryKey: ["audit-logs"],
    queryFn: async () => (await api.get<AuditLog[]>("/admin/audit-logs")).data,
    enabled: tab === "audit",
  });
  const logins = useQuery({
    queryKey: ["login-history"],
    queryFn: async () => (await api.get<LoginHistoryEntry[]>("/admin/login-history")).data,
    enabled: tab === "logins",
  });

  return (
    <div>
      <PageHeader
        title="Audit & security"
        subtitle="Who changed what, and who signed in — wired to /admin/audit-logs"
      />
      <div className="mb-4 flex gap-2">
        <button
          onClick={() => setTab("audit")}
          className={`rounded-lg px-3.5 py-2 text-sm font-medium ${tab === "audit" ? "bg-accent text-black" : "bg-surface-2 text-neutral-300 border border-border"}`}
        >
          Admin activity
        </button>
        <button
          onClick={() => setTab("logins")}
          className={`rounded-lg px-3.5 py-2 text-sm font-medium ${tab === "logins" ? "bg-accent text-black" : "bg-surface-2 text-neutral-300 border border-border"}`}
        >
          Login history
        </button>
      </div>

      {tab === "audit" ? (
        audit.isLoading ? (
          <Spinner />
        ) : !audit.data || audit.data.length === 0 ? (
          <Card><EmptyState message="No admin activity recorded yet." /></Card>
        ) : (
          <Table>
            <thead>
              <tr>
                <Th>Action</Th>
                <Th>Resource</Th>
                <Th>Details</Th>
                <Th>IP</Th>
                <Th>When</Th>
              </tr>
            </thead>
            <tbody>
              {audit.data.map((l) => (
                <tr key={l.id}>
                  <Td><Badge tone="info">{l.action}</Badge></Td>
                  <Td className="text-xs">{l.resource_type}:{l.resource_id.slice(0, 8)}</Td>
                  <Td className="max-w-md truncate text-xs">{l.details ? JSON.stringify(l.details) : "—"}</Td>
                  <Td className="text-xs">{l.ip_address ?? "—"}</Td>
                  <Td className="text-xs">{new Date(l.created_at).toLocaleString()}</Td>
                </tr>
              ))}
            </tbody>
          </Table>
        )
      ) : logins.isLoading ? (
        <Spinner />
      ) : !logins.data || logins.data.length === 0 ? (
        <Card><EmptyState message="No login attempts recorded yet." /></Card>
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>User</Th>
              <Th>Result</Th>
              <Th>IP</Th>
              <Th>When</Th>
            </tr>
          </thead>
          <tbody>
            {logins.data.map((h) => (
              <tr key={h.id}>
                <Td>{h.username_attempted}</Td>
                <Td>
                  <Badge tone={h.success ? "success" : "danger"}>
                    {h.success ? "Success" : "Failed"}
                  </Badge>
                </Td>
                <Td className="text-xs">{h.ip_address ?? "—"}</Td>
                <Td className="text-xs">{new Date(h.created_at).toLocaleString()}</Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </div>
  );
}
