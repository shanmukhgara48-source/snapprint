"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { DeliverySetting } from "@/lib/types";

export default function DeliverySettingsPage() {
  const queryClient = useQueryClient();
  const [editing, setEditing] = useState<DeliverySetting | null>(null);

  const { data: settings, isLoading } = useQuery({
    queryKey: ["admin", "delivery-settings"],
    queryFn: async () => (await api.get<DeliverySetting[]>("/admin/delivery-settings")).data,
  });

  const updateMutation = useMutation({
    mutationFn: async ({ type, payload }: { type: string; payload: Record<string, unknown> }) =>
      api.put(`/admin/delivery-settings/${type}`, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "delivery-settings"] });
      setEditing(null);
    },
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold">Delivery Settings</h1>
        <p className="text-sm text-gray-500">Configure delivery types, pricing, and availability</p>
      </div>

      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-left text-gray-500">
            <tr>
              <th className="px-4 py-2 font-medium">Type</th>
              <th className="px-4 py-2 font-medium">Label</th>
              <th className="px-4 py-2 font-medium">Price</th>
              <th className="px-4 py-2 font-medium">Days</th>
              <th className="px-4 py-2 font-medium">Status</th>
              <th className="px-4 py-2 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr><td colSpan={6} className="px-4 py-6 text-center text-gray-400">Loading...</td></tr>
            )}
            {settings?.map((s) => (
              <tr key={s.type} className="border-t border-gray-100">
                <td className="px-4 py-2 font-mono">{s.type}</td>
                <td className="px-4 py-2">{s.label}</td>
                <td className="px-4 py-2">₹{s.price.toFixed(2)}</td>
                <td className="px-4 py-2">{s.days_label}</td>
                <td className="px-4 py-2">
                  <button
                    onClick={() => updateMutation.mutate({ type: s.type, payload: { is_active: !s.is_active } })}
                    className={`rounded-full px-2 py-0.5 text-xs ${s.is_active ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-500"}`}
                  >
                    {s.is_active ? "Active" : "Disabled"}
                  </button>
                </td>
                <td className="px-4 py-2">
                  <button onClick={() => setEditing(s)} className="text-blue-600 hover:underline">Edit</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {editing && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4">
          <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-xl">
            <h2 className="mb-4 text-lg font-semibold">Edit {editing.type}</h2>

            <label className="mb-1 block text-sm font-medium text-gray-700">Label</label>
            <input
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={editing.label}
              onChange={(e) => setEditing({ ...editing, label: e.target.value })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Price</label>
            <input
              type="number"
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={editing.price}
              onChange={(e) => setEditing({ ...editing, price: Number(e.target.value) })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Days Label</label>
            <input
              className="mb-4 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={editing.days_label}
              onChange={(e) => setEditing({ ...editing, days_label: e.target.value })}
            />

            <div className="flex justify-end gap-2">
              <button onClick={() => setEditing(null)} className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50">
                Cancel
              </button>
              <button
                onClick={() =>
                  updateMutation.mutate({
                    type: editing.type,
                    payload: { label: editing.label, price: editing.price, days_label: editing.days_label },
                  })
                }
                disabled={updateMutation.isPending}
                className="rounded-md bg-gray-900 px-3 py-2 text-sm text-white hover:bg-gray-800 disabled:opacity-50"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
