"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { AppSettingEntry, AuditLog, LoginHistoryEntry } from "@/lib/types";

type Tab = "settings" | "audit" | "logins";

interface SettingField {
  name: string;
  label: string;
  type?: "checkbox";
}

const KNOWN_SETTINGS: { key: string; label: string; fields: SettingField[] }[] = [
  { key: "maintenance_mode", label: "Maintenance Mode", fields: [{ name: "enabled", label: "Enabled", type: "checkbox" }] },
  { key: "order_limits", label: "Order Limits", fields: [{ name: "min", label: "Min Order Value" }, { name: "max", label: "Max Order Value" }] },
  { key: "company_details", label: "Company Details", fields: [{ name: "name", label: "Company Name" }, { name: "support_phone", label: "Support Phone" }, { name: "support_email", label: "Support Email" }] },
];

export default function SettingsPage() {
  const [tab, setTab] = useState<Tab>("settings");
  const queryClient = useQueryClient();

  const { data: settings } = useQuery({
    queryKey: ["admin", "settings"],
    queryFn: async () => (await api.get<AppSettingEntry[]>("/admin/settings")).data,
  });

  const { data: auditLogs } = useQuery({
    queryKey: ["admin", "audit-logs"],
    queryFn: async () => (await api.get<AuditLog[]>("/admin/audit-logs")).data,
    enabled: tab === "audit",
  });

  const { data: loginHistory } = useQuery({
    queryKey: ["admin", "login-history"],
    queryFn: async () => (await api.get<LoginHistoryEntry[]>("/admin/login-history")).data,
    enabled: tab === "logins",
  });

  const updateMutation = useMutation({
    mutationFn: async ({ key, value }: { key: string; value: Record<string, unknown> }) =>
      api.put(`/admin/settings/${key}`, { value }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["admin", "settings"] }),
  });

  function valueFor(key: string): Record<string, unknown> {
    return (settings?.find((s) => s.key === key)?.value as Record<string, unknown>) || {};
  }

  function updateField(key: string, field: string, value: unknown) {
    const current = valueFor(key);
    updateMutation.mutate({ key, value: { ...current, [field]: value } });
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold">Settings</h1>
        <p className="text-sm text-gray-500">Company configuration, audit trail, and login history</p>
      </div>

      <div className="flex gap-1 border-b border-gray-200">
        {(["settings", "audit", "logins"] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-4 py-2 text-sm ${tab === t ? "border-b-2 border-gray-900 font-medium" : "text-gray-500"}`}
          >
            {t === "settings" ? "App Settings" : t === "audit" ? "Audit Log" : "Login History"}
          </button>
        ))}
      </div>

      {tab === "settings" && (
        <div className="space-y-4">
          {KNOWN_SETTINGS.map((s) => {
            const current = valueFor(s.key);
            return (
              <div key={s.key} className="rounded-xl border border-gray-200 bg-white p-5">
                <h2 className="mb-3 text-sm font-semibold text-gray-700">{s.label}</h2>
                <div className="flex flex-wrap gap-4">
                  {s.fields.map((f) =>
                    f.type === "checkbox" ? (
                      <label key={f.name} className="flex items-center gap-2 text-sm">
                        <input
                          type="checkbox"
                          checked={Boolean(current[f.name])}
                          onChange={(e) => updateField(s.key, f.name, e.target.checked)}
                        />
                        {f.label}
                      </label>
                    ) : (
                      <div key={f.name}>
                        <label className="mb-1 block text-xs text-gray-500">{f.label}</label>
                        <input
                          className="rounded-md border border-gray-300 px-3 py-2 text-sm"
                          defaultValue={String(current[f.name] ?? "")}
                          onBlur={(e) => updateField(s.key, f.name, e.target.value)}
                        />
                      </div>
                    )
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {tab === "audit" && (
        <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-left text-gray-500">
              <tr>
                <th className="px-4 py-2 font-medium">Action</th>
                <th className="px-4 py-2 font-medium">Resource</th>
                <th className="px-4 py-2 font-medium">Admin</th>
                <th className="px-4 py-2 font-medium">IP</th>
                <th className="px-4 py-2 font-medium">Time</th>
              </tr>
            </thead>
            <tbody>
              {auditLogs?.map((l) => (
                <tr key={l.id} className="border-t border-gray-100">
                  <td className="px-4 py-2 font-mono text-xs">{l.action}</td>
                  <td className="px-4 py-2 text-xs">{l.resource_type} {l.resource_id ? `#${l.resource_id.slice(0, 8)}` : ""}</td>
                  <td className="px-4 py-2 font-mono text-xs">{l.admin_user_id.slice(0, 8)}</td>
                  <td className="px-4 py-2 text-gray-500">{l.ip_address || "—"}</td>
                  <td className="px-4 py-2 text-gray-500">{new Date(l.created_at).toLocaleString()}</td>
                </tr>
              ))}
              {auditLogs?.length === 0 && (
                <tr><td colSpan={5} className="px-4 py-6 text-center text-gray-400">No audit log entries</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {tab === "logins" && (
        <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-left text-gray-500">
              <tr>
                <th className="px-4 py-2 font-medium">Username</th>
                <th className="px-4 py-2 font-medium">Result</th>
                <th className="px-4 py-2 font-medium">IP</th>
                <th className="px-4 py-2 font-medium">Time</th>
              </tr>
            </thead>
            <tbody>
              {loginHistory?.map((h) => (
                <tr key={h.id} className="border-t border-gray-100">
                  <td className="px-4 py-2">{h.username_attempted}</td>
                  <td className="px-4 py-2">
                    <span className={`rounded-full px-2 py-0.5 text-xs ${h.success ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                      {h.success ? "Success" : "Failed"}
                    </span>
                  </td>
                  <td className="px-4 py-2 text-gray-500">{h.ip_address || "—"}</td>
                  <td className="px-4 py-2 text-gray-500">{new Date(h.created_at).toLocaleString()}</td>
                </tr>
              ))}
              {loginHistory?.length === 0 && (
                <tr><td colSpan={4} className="px-4 py-6 text-center text-gray-400">No login attempts recorded</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
