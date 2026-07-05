import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { AppSetting, AuditLog, LoginHistoryEntry } from "../../lib/types";
import { Badge, Button, Card, Input, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { useAuth } from "../../lib/auth";
import clsx from "clsx";

const TABS = ["App Settings", "Audit Log", "Login History"] as const;

export default function Settings() {
  const [tab, setTab] = useState<(typeof TABS)[number]>("App Settings");
  const { role } = useAuth();
  const canSeeLogs = role === "super_admin" || role === "manager";

  return (
    <div>
      <PageHeader title="Settings" subtitle="App configuration, audit trail & login history" />
      <div className="mb-5 flex gap-1 border-b border-border">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={clsx(
              "px-3 py-2 text-sm border-b-2 -mb-px transition-colors",
              tab === t ? "border-accent text-accent" : "border-transparent text-neutral-400 hover:text-white",
            )}
          >
            {t}
          </button>
        ))}
      </div>
      {tab === "App Settings" && <AppSettingsTab />}
      {tab === "Audit Log" && (canSeeLogs ? <AuditLogTab /> : <NoAccess />)}
      {tab === "Login History" && (canSeeLogs ? <LoginHistoryTab /> : <NoAccess />)}
    </div>
  );
}

function NoAccess() {
  return (
    <Card>
      <p className="text-sm text-neutral-400">Only super_admin and manager roles can view this.</p>
    </Card>
  );
}

function AppSettingsTab() {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery({
    queryKey: ["settings"],
    queryFn: async () => (await api.get<AppSetting[]>("/admin/settings")).data,
  });
  const [key, setKey] = useState("");
  const [value, setValue] = useState("");

  const updateMut = useMutation({
    mutationFn: () => api.put(`/admin/settings/${key}`, { value: JSON.parse(value || "{}") }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["settings"] });
      setKey("");
      setValue("");
    },
  });

  if (isLoading) return <Spinner />;

  return (
    <div className="space-y-4">
      <Card>
        <div className="mb-3 text-sm font-medium text-white">Add / update a setting</div>
        <div className="flex gap-2">
          <Input placeholder="key (e.g. maintenance_mode)" value={key} onChange={(e) => setKey(e.target.value)} />
          <Input placeholder='JSON value, e.g. {"enabled": true}' value={value} onChange={(e) => setValue(e.target.value)} />
          <Button onClick={() => updateMut.mutate()} disabled={!key || updateMut.isPending}>
            Save
          </Button>
        </div>
      </Card>
      <Table>
        <thead>
          <tr>
            <Th>Key</Th>
            <Th>Value</Th>
            <Th>Updated</Th>
          </tr>
        </thead>
        <tbody>
          {data?.map((s) => (
            <tr key={s.key}>
              <Td className="font-mono">{s.key}</Td>
              <Td className="font-mono text-xs">{JSON.stringify(s.value)}</Td>
              <Td>{new Date(s.updated_at).toLocaleString()}</Td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}

function AuditLogTab() {
  const { data, isLoading } = useQuery({
    queryKey: ["audit-logs"],
    queryFn: async () => (await api.get<AuditLog[]>("/admin/audit-logs")).data,
  });
  if (isLoading) return <Spinner />;
  return (
    <Table>
      <thead>
        <tr>
          <Th>Action</Th>
          <Th>Resource</Th>
          <Th>Admin</Th>
          <Th>IP</Th>
          <Th>When</Th>
        </tr>
      </thead>
      <tbody>
        {data?.map((l) => (
          <tr key={l.id}>
            <Td className="font-mono text-xs">{l.action}</Td>
            <Td>
              {l.resource_type} #{l.resource_id.slice(0, 8)}
            </Td>
            <Td className="font-mono text-xs">{l.admin_user_id.slice(0, 8)}</Td>
            <Td>{l.ip_address ?? "—"}</Td>
            <Td>{new Date(l.created_at).toLocaleString()}</Td>
          </tr>
        ))}
      </tbody>
    </Table>
  );
}

function LoginHistoryTab() {
  const { data, isLoading } = useQuery({
    queryKey: ["login-history"],
    queryFn: async () => (await api.get<LoginHistoryEntry[]>("/admin/login-history")).data,
  });
  if (isLoading) return <Spinner />;
  return (
    <Table>
      <thead>
        <tr>
          <Th>Username attempted</Th>
          <Th>Result</Th>
          <Th>IP</Th>
          <Th>When</Th>
        </tr>
      </thead>
      <tbody>
        {data?.map((h) => (
          <tr key={h.id}>
            <Td>{h.username_attempted}</Td>
            <Td>
              <Badge tone={h.success ? "success" : "danger"}>{h.success ? "Success" : "Failed"}</Badge>
            </Td>
            <Td>{h.ip_address ?? "—"}</Td>
            <Td>{new Date(h.created_at).toLocaleString()}</Td>
          </tr>
        ))}
      </tbody>
    </Table>
  );
}
