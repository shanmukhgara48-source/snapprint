"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { OrderDetail } from "@/lib/types";

const STATUSES = ["confirmed", "printing", "out_for_delivery", "delivered", "cancelled"];

interface DeliveryPartner {
  id: string;
  phone: string;
  display_name: string | null;
}

export default function OrderDetailPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const queryClient = useQueryClient();
  const [notes, setNotes] = useState<string | null>(null);
  const [assignId, setAssignId] = useState("");

  const { data: order, isLoading } = useQuery({
    queryKey: ["admin", "order", params.id],
    queryFn: async () => (await api.get<OrderDetail>(`/admin/orders/${params.id}`)).data,
  });

  const { data: partners } = useQuery({
    queryKey: ["admin", "delivery-partners"],
    queryFn: async () => (await api.get<DeliveryPartner[]>("/admin/delivery-partners")).data,
  });

  const updateMutation = useMutation({
    mutationFn: async (payload: { status?: string; notes?: string }) =>
      api.patch(`/admin/orders/${params.id}`, payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["admin", "order", params.id] }),
  });

  const assignMutation = useMutation({
    mutationFn: async (delivery_partner_id: string) =>
      api.post(`/admin/orders/${params.id}/assign`, { delivery_partner_id }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["admin", "order", params.id] }),
  });

  if (isLoading) return <div className="text-sm text-gray-400">Loading order...</div>;
  if (!order) return <div className="text-sm text-red-500">Order not found.</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <button onClick={() => router.push("/orders")} className="mb-1 text-xs text-gray-500 hover:underline">
            ← Back to orders
          </button>
          <h1 className="text-xl font-semibold">Order {order.id.slice(0, 8)}</h1>
          <p className="text-sm text-gray-500">Placed {new Date(order.created_at).toLocaleString()}</p>
        </div>
        <select
          value={order.status}
          onChange={(e) => updateMutation.mutate({ status: e.target.value })}
          className="rounded-md border border-gray-300 px-3 py-2 text-sm"
        >
          {STATUSES.map((s) => (
            <option key={s} value={s}>{s.replace("_", " ")}</option>
          ))}
        </select>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <div className="rounded-xl border border-gray-200 bg-white p-5">
            <h2 className="mb-3 text-sm font-semibold text-gray-700">Items</h2>
            <table className="w-full text-sm">
              <thead className="text-left text-gray-500">
                <tr>
                  <th className="pb-2 font-medium">Product</th>
                  <th className="pb-2 font-medium">Size</th>
                  <th className="pb-2 font-medium">Qty</th>
                  <th className="pb-2 font-medium">Unit Price</th>
                  <th className="pb-2 font-medium">Photo</th>
                </tr>
              </thead>
              <tbody>
                {order.items.map((i) => (
                  <tr key={i.id} className="border-t border-gray-100">
                    <td className="py-2">{i.product_name || "—"}</td>
                    <td className="py-2">{i.selected_size || "—"}</td>
                    <td className="py-2">{i.quantity}</td>
                    <td className="py-2">₹{i.unit_price.toFixed(2)}</td>
                    <td className="py-2">
                      {i.image_url ? (
                        <a href={i.image_url} target="_blank" rel="noreferrer" className="text-blue-600 hover:underline">
                          View
                        </a>
                      ) : (
                        "—"
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="rounded-xl border border-gray-200 bg-white p-5">
            <h2 className="mb-3 text-sm font-semibold text-gray-700">Delivery Timeline</h2>
            {order.timeline.length === 0 && <p className="text-sm text-gray-400">No tracking events yet.</p>}
            <ol className="space-y-2">
              {order.timeline.map((t, idx) => (
                <li key={idx} className="flex items-center justify-between text-sm">
                  <span className="capitalize">{t.status.replace("_", " ")}</span>
                  <span className="text-gray-500">{new Date(t.timestamp).toLocaleString()}</span>
                </li>
              ))}
            </ol>
          </div>

          <div className="rounded-xl border border-gray-200 bg-white p-5">
            <h2 className="mb-3 text-sm font-semibold text-gray-700">Notes</h2>
            <textarea
              className="mb-2 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              rows={3}
              defaultValue={order.notes || ""}
              onChange={(e) => setNotes(e.target.value)}
            />
            <button
              onClick={() => notes !== null && updateMutation.mutate({ notes })}
              disabled={notes === null || updateMutation.isPending}
              className="rounded-md bg-gray-900 px-3 py-2 text-sm text-white hover:bg-gray-800 disabled:opacity-50"
            >
              Save Notes
            </button>
          </div>
        </div>

        <div className="space-y-6">
          <div className="rounded-xl border border-gray-200 bg-white p-5">
            <h2 className="mb-3 text-sm font-semibold text-gray-700">Summary</h2>
            <dl className="space-y-2 text-sm">
              <div className="flex justify-between"><dt className="text-gray-500">Customer</dt><dd>{order.customer_phone || "—"}</dd></div>
              <div className="flex justify-between"><dt className="text-gray-500">Address</dt><dd className="text-right">{order.address || "—"}</dd></div>
              <div className="flex justify-between"><dt className="text-gray-500">Delivery type</dt><dd>{order.delivery_type}</dd></div>
              <div className="flex justify-between"><dt className="text-gray-500">Delivery charge</dt><dd>₹{order.delivery_charge.toFixed(2)}</dd></div>
              <div className="flex justify-between"><dt className="text-gray-500">Discount</dt><dd>₹{order.discount.toFixed(2)}</dd></div>
              <div className="flex justify-between"><dt className="text-gray-500">Coupon</dt><dd>{order.coupon_code || "—"}</dd></div>
              <div className="flex justify-between font-medium"><dt>Total</dt><dd>₹{order.total_price.toFixed(2)}</dd></div>
              <div className="flex justify-between"><dt className="text-gray-500">Razorpay order</dt><dd className="truncate">{order.razorpay_order_id || "—"}</dd></div>
              <div className="flex justify-between"><dt className="text-gray-500">Razorpay payment</dt><dd className="truncate">{order.razorpay_payment_id || "—"}</dd></div>
            </dl>
          </div>

          <div className="rounded-xl border border-gray-200 bg-white p-5">
            <h2 className="mb-3 text-sm font-semibold text-gray-700">Assign Delivery Partner</h2>
            {order.delivery_partner_id && (
              <p className="mb-2 text-xs text-gray-500">Currently assigned: {order.delivery_partner_id.slice(0, 8)}</p>
            )}
            <select
              value={assignId}
              onChange={(e) => setAssignId(e.target.value)}
              className="mb-2 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
            >
              <option value="">Select partner...</option>
              {partners?.map((p) => (
                <option key={p.id} value={p.id}>{p.display_name || p.phone}</option>
              ))}
            </select>
            <button
              onClick={() => assignId && assignMutation.mutate(assignId)}
              disabled={!assignId || assignMutation.isPending}
              className="w-full rounded-md bg-gray-900 px-3 py-2 text-sm text-white hover:bg-gray-800 disabled:opacity-50"
            >
              Assign
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
