"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { AdminAccount } from "@/lib/types";

const ROLES = ["super_admin", "manager", "support_staff", "printing_staff", "delivery_staff"];
const EMPTY_FORM = { username: "", password: "", role: "manager" };

export default function AdminsPage() {
  const queryClient = useQueryClient();
  const [form, setForm] = useState<typeof EMPTY_FORM | null>(null);

  const { data: admins, isLoading } = useQuery({
    queryKey: ["admin", "admins"],
    queryFn: async () => (await api.get<AdminAccount[]>("/admin/admins")).data,
  });

  const createMutation = useMutation({
    mutationFn: async (payload: typeof EMPTY_FORM) => api.post("/admin/admins", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "admins"] });
      setForm(null);
    },
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: Record<string, unknown> }) =>
      api.patch(`/admin/admins/${id}`, payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["admin", "admins"] }),
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Admin Users</h1>
          <p className="text-sm text-gray-500">Manage admin accounts and roles</p>
        </div>
        <button
          onClick={() => setForm({ ...EMPTY_FORM })}
          className="flex items-center gap-1 rounded-md bg-gray-900 px-3 py-2 text-sm text-white hover:bg-gray-800"
        >
          <Plus size={14} /> New Admin
        </button>
      </div>

      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-left text-gray-500">
            <tr>
              <th className="px-4 py-2 font-medium">Username</th>
              <th className="px-4 py-2 font-medium">Role</th>
              <th className="px-4 py-2 font-medium">Status</th>
              <th className="px-4 py-2 font-medium">Last Login</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr><td colSpan={4} className="px-4 py-6 text-center text-gray-400">Loading...</td></tr>
            )}
            {admins?.map((a) => (
              <tr key={a.id} className="border-t border-gray-100">
                <td className="px-4 py-2">{a.username}</td>
                <td className="px-4 py-2">
                  <select
                    value={a.role}
                    onChange={(e) => updateMutation.mutate({ id: a.id, payload: { role: e.target.value } })}
                    className="rounded-md border border-gray-300 px-2 py-1 text-sm"
                  >
                    {ROLES.map((r) => (
                      <option key={r} value={r}>{r.replace("_", " ")}</option>
                    ))}
                  </select>
                </td>
                <td className="px-4 py-2">
                  <button
                    onClick={() => updateMutation.mutate({ id: a.id, payload: { is_active: !a.is_active } })}
                    className={`rounded-full px-2 py-0.5 text-xs ${a.is_active ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-500"}`}
                  >
                    {a.is_active ? "Active" : "Disabled"}
                  </button>
                </td>
                <td className="px-4 py-2 text-gray-500">
                  {a.last_login_at ? new Date(a.last_login_at).toLocaleString() : "Never"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {form && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4">
          <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-xl">
            <h2 className="mb-4 text-lg font-semibold">New Admin</h2>

            <label className="mb-1 block text-sm font-medium text-gray-700">Username</label>
            <input
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.username}
              onChange={(e) => setForm({ ...form, username: e.target.value })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Password</label>
            <input
              type="password"
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Role</label>
            <select
              className="mb-4 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.role}
              onChange={(e) => setForm({ ...form, role: e.target.value })}
            >
              {ROLES.map((r) => (
                <option key={r} value={r}>{r.replace("_", " ")}</option>
              ))}
            </select>

            <div className="flex justify-end gap-2">
              <button onClick={() => setForm(null)} className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50">
                Cancel
              </button>
              <button
                onClick={() => createMutation.mutate(form)}
                disabled={createMutation.isPending}
                className="rounded-md bg-gray-900 px-3 py-2 text-sm text-white hover:bg-gray-800 disabled:opacity-50"
              >
                Create Admin
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
