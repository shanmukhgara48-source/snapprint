"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { api } from "@/lib/api";
import { exportCsv } from "@/lib/csv";
import { OrderListItem } from "@/lib/types";

const STATUSES = ["confirmed", "printing", "out_for_delivery", "delivered", "cancelled"];

export default function OrdersPage() {
  const [status, setStatus] = useState("");
  const [q, setQ] = useState("");

  const { data: orders, isLoading } = useQuery({
    queryKey: ["admin", "orders", status, q],
    queryFn: async () =>
      (await api.get<OrderListItem[]>("/admin/orders", { params: { status: status || undefined, q: q || undefined } }))
        .data,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Orders</h1>
          <p className="text-sm text-gray-500">Track and manage customer orders</p>
        </div>
        <button
          onClick={() => orders && exportCsv("orders.csv", orders as unknown as Record<string, unknown>[])}
          className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50"
        >
          Export CSV
        </button>
      </div>

      <div className="flex gap-3">
        <input
          placeholder="Search by customer phone..."
          value={q}
          onChange={(e) => setQ(e.target.value)}
          className="w-full max-w-sm rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-gray-500 focus:outline-none"
        />
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="rounded-md border border-gray-300 px-3 py-2 text-sm"
        >
          <option value="">All statuses</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>{s.replace("_", " ")}</option>
          ))}
        </select>
      </div>

      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-left text-gray-500">
            <tr>
              <th className="px-4 py-2 font-medium">Order ID</th>
              <th className="px-4 py-2 font-medium">Customer</th>
              <th className="px-4 py-2 font-medium">Items</th>
              <th className="px-4 py-2 font-medium">Total</th>
              <th className="px-4 py-2 font-medium">Status</th>
              <th className="px-4 py-2 font-medium">Placed</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr>
                <td colSpan={6} className="px-4 py-6 text-center text-gray-400">Loading...</td>
              </tr>
            )}
            {orders?.map((o) => (
              <tr key={o.id} className="border-t border-gray-100 hover:bg-gray-50">
                <td className="px-4 py-2">
                  <Link href={`/orders/${o.id}`} className="text-blue-600 hover:underline">
                    {o.id.slice(0, 8)}
                  </Link>
                </td>
                <td className="px-4 py-2">{o.customer_phone || "—"}</td>
                <td className="px-4 py-2">{o.item_count}</td>
                <td className="px-4 py-2">₹{o.total_price.toFixed(2)}</td>
                <td className="px-4 py-2">
                  <span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs capitalize">
                    {o.status.replace("_", " ")}
                  </span>
                </td>
                <td className="px-4 py-2 text-gray-500">{new Date(o.created_at).toLocaleString()}</td>
              </tr>
            ))}
            {!isLoading && orders?.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-6 text-center text-gray-400">No orders found</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
