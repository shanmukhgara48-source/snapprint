"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus, Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { Coupon } from "@/lib/types";

const EMPTY_FORM = { code: "", discount_type: "percent", value: "", min_order: "0", expires_at: "" };

export default function CouponsPage() {
  const queryClient = useQueryClient();
  const [form, setForm] = useState<typeof EMPTY_FORM | null>(null);

  const { data: coupons, isLoading } = useQuery({
    queryKey: ["admin", "coupons"],
    queryFn: async () => (await api.get<Coupon[]>("/admin/coupons")).data,
  });

  const createMutation = useMutation({
    mutationFn: async (payload: Record<string, unknown>) => api.post("/admin/coupons", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "coupons"] });
      setForm(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/admin/coupons/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["admin", "coupons"] }),
  });

  function submit() {
    if (!form) return;
    createMutation.mutate({
      code: form.code,
      discount_type: form.discount_type,
      value: parseFloat(form.value),
      min_order: parseFloat(form.min_order || "0"),
      expires_at: form.expires_at ? new Date(form.expires_at).toISOString() : null,
    });
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Coupons</h1>
          <p className="text-sm text-gray-500">Discount codes for checkout</p>
        </div>
        <button
          onClick={() => setForm({ ...EMPTY_FORM })}
          className="flex items-center gap-1 rounded-md bg-gray-900 px-3 py-2 text-sm text-white hover:bg-gray-800"
        >
          <Plus size={14} /> New Coupon
        </button>
      </div>

      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-left text-gray-500">
            <tr>
              <th className="px-4 py-2 font-medium">Code</th>
              <th className="px-4 py-2 font-medium">Type</th>
              <th className="px-4 py-2 font-medium">Value</th>
              <th className="px-4 py-2 font-medium">Min Order</th>
              <th className="px-4 py-2 font-medium">Expires</th>
              <th className="px-4 py-2 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr><td colSpan={6} className="px-4 py-6 text-center text-gray-400">Loading...</td></tr>
            )}
            {coupons?.map((c) => (
              <tr key={c.id} className="border-t border-gray-100">
                <td className="px-4 py-2 font-mono">{c.code}</td>
                <td className="px-4 py-2 capitalize">{c.discount_type}</td>
                <td className="px-4 py-2">{c.discount_type === "percent" ? `${c.value}%` : `₹${c.value}`}</td>
                <td className="px-4 py-2">₹{c.min_order.toFixed(2)}</td>
                <td className="px-4 py-2">{c.expires_at ? new Date(c.expires_at).toLocaleDateString() : "Never"}</td>
                <td className="px-4 py-2">
                  <button
                    onClick={() => confirm(`Delete coupon ${c.code}?`) && deleteMutation.mutate(c.id)}
                    className="text-gray-500 hover:text-red-600"
                  >
                    <Trash2 size={14} />
                  </button>
                </td>
              </tr>
            ))}
            {!isLoading && coupons?.length === 0 && (
              <tr><td colSpan={6} className="px-4 py-6 text-center text-gray-400">No coupons yet</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {form && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="mb-4 text-lg font-semibold">New Coupon</h2>

            <label className="mb-1 block text-sm font-medium text-gray-700">Code</label>
            <input
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm uppercase"
              value={form.code}
              onChange={(e) => setForm({ ...form, code: e.target.value })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Type</label>
            <select
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.discount_type}
              onChange={(e) => setForm({ ...form, discount_type: e.target.value })}
            >
              <option value="percent">Percent</option>
              <option value="flat">Flat</option>
            </select>

            <label className="mb-1 block text-sm font-medium text-gray-700">Value</label>
            <input
              type="number"
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.value}
              onChange={(e) => setForm({ ...form, value: e.target.value })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Min Order</label>
            <input
              type="number"
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.min_order}
              onChange={(e) => setForm({ ...form, min_order: e.target.value })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Expires At (optional)</label>
            <input
              type="date"
              className="mb-4 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.expires_at}
              onChange={(e) => setForm({ ...form, expires_at: e.target.value })}
            />

            <div className="flex justify-end gap-2">
              <button onClick={() => setForm(null)} className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50">
                Cancel
              </button>
              <button
                onClick={submit}
                disabled={createMutation.isPending}
                className="rounded-md bg-gray-900 px-3 py-2 text-sm text-white hover:bg-gray-800 disabled:opacity-50"
              >
                Create Coupon
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
