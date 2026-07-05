"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { exportCsv } from "@/lib/csv";
import { PaymentAttempt } from "@/lib/types";

export default function PaymentsPage() {
  const [status, setStatus] = useState("");

  const { data: payments, isLoading } = useQuery({
    queryKey: ["admin", "payments", status],
    queryFn: async () => (await api.get<PaymentAttempt[]>("/admin/payments", { params: { status: status || undefined } })).data,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Payments</h1>
          <p className="text-sm text-gray-500">Every Razorpay verification attempt, success or failure</p>
        </div>
        <button
          onClick={() => payments && exportCsv("payments.csv", payments as unknown as Record<string, unknown>[])}
          className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50"
        >
          Export CSV
        </button>
      </div>

      <select value={status} onChange={(e) => setStatus(e.target.value)} className="rounded-md border border-gray-300 px-3 py-2 text-sm">
        <option value="">All statuses</option>
        <option value="success">Success</option>
        <option value="failed">Failed</option>
      </select>

      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-left text-gray-500">
            <tr>
              <th className="px-4 py-2 font-medium">Razorpay Order</th>
              <th className="px-4 py-2 font-medium">Razorpay Payment</th>
              <th className="px-4 py-2 font-medium">Status</th>
              <th className="px-4 py-2 font-medium">Reason</th>
              <th className="px-4 py-2 font-medium">Time</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr><td colSpan={5} className="px-4 py-6 text-center text-gray-400">Loading...</td></tr>
            )}
            {payments?.map((p) => (
              <tr key={p.id} className="border-t border-gray-100">
                <td className="px-4 py-2 font-mono text-xs">{p.razorpay_order_id}</td>
                <td className="px-4 py-2 font-mono text-xs">{p.razorpay_payment_id || "—"}</td>
                <td className="px-4 py-2">
                  <span className={`rounded-full px-2 py-0.5 text-xs ${p.status === "success" ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                    {p.status}
                  </span>
                </td>
                <td className="px-4 py-2 text-gray-500">{p.reason || "—"}</td>
                <td className="px-4 py-2 text-gray-500">{new Date(p.created_at).toLocaleString()}</td>
              </tr>
            ))}
            {!isLoading && payments?.length === 0 && (
              <tr><td colSpan={5} className="px-4 py-6 text-center text-gray-400">No payment attempts recorded</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
