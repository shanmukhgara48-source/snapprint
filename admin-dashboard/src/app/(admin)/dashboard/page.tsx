"use client";

import { useQuery } from "@tanstack/react-query";
import {
  Line,
  LineChart,
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { api } from "@/lib/api";

interface DashboardStats {
  revenue: { today: number; week: number; month: number; year: number };
  orders: { today: number; by_status: Record<string, number> };
  users: { total: number; new_this_month: number };
  payments: { failed: number };
  photos: { total_uploaded: number };
  top_products: { name: string; quantity: number }[];
}

interface ChartsResponse {
  revenue: { date: string; revenue: number }[];
  orders: { date: string; orders: number }[];
  users: { date: string; new_users: number }[];
}

function KpiCard({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="rounded-xl border border-gray-200 bg-white p-5">
      <div className="text-xs font-medium text-gray-500">{label}</div>
      <div className="mt-1 text-2xl font-semibold">{value}</div>
    </div>
  );
}

export default function DashboardPage() {
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ["admin", "analytics", "dashboard"],
    queryFn: async () => (await api.get<DashboardStats>("/admin/analytics/dashboard")).data,
  });

  const { data: charts, isLoading: chartsLoading } = useQuery({
    queryKey: ["admin", "analytics", "charts"],
    queryFn: async () => (await api.get<ChartsResponse>("/admin/analytics/charts", { params: { days: 30 } })).data,
  });

  if (statsLoading || chartsLoading) {
    return <div className="text-sm text-gray-400">Loading dashboard...</div>;
  }

  if (!stats || !charts) {
    return <div className="text-sm text-red-500">Failed to load dashboard data.</div>;
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-xl font-semibold">Dashboard</h1>
        <p className="text-sm text-gray-500">Live overview of SnapPrint operations</p>
      </div>

      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        <KpiCard label="Revenue Today" value={`₹${stats.revenue.today.toFixed(2)}`} />
        <KpiCard label="Revenue This Week" value={`₹${stats.revenue.week.toFixed(2)}`} />
        <KpiCard label="Revenue This Month" value={`₹${stats.revenue.month.toFixed(2)}`} />
        <KpiCard label="Revenue This Year" value={`₹${stats.revenue.year.toFixed(2)}`} />
        <KpiCard label="Orders Today" value={stats.orders.today} />
        <KpiCard label="Total Users" value={stats.users.total} />
        <KpiCard label="New Users This Month" value={stats.users.new_this_month} />
        <KpiCard label="Failed Payments" value={stats.payments.failed} />
        <KpiCard label="Photos Uploaded" value={stats.photos.total_uploaded} />
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-5">
        <h2 className="mb-4 text-sm font-semibold text-gray-700">Orders by Status</h2>
        <div className="flex flex-wrap gap-3">
          {Object.entries(stats.orders.by_status).map(([status, count]) => (
            <div key={status} className="rounded-md bg-gray-100 px-3 py-1.5 text-sm">
              <span className="font-medium capitalize">{status}</span>: {count}
            </div>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="mb-4 text-sm font-semibold text-gray-700">Revenue (last 30 days)</h2>
          <ResponsiveContainer width="100%" height={260}>
            <LineChart data={charts.revenue}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Line type="monotone" dataKey="revenue" stroke="#111827" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="mb-4 text-sm font-semibold text-gray-700">Orders (last 30 days)</h2>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={charts.orders}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="orders" fill="#111827" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5 lg:col-span-2">
          <h2 className="mb-4 text-sm font-semibold text-gray-700">User Growth (last 30 days)</h2>
          <ResponsiveContainer width="100%" height={260}>
            <LineChart data={charts.users}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Line type="monotone" dataKey="new_users" stroke="#2563eb" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-5">
        <h2 className="mb-4 text-sm font-semibold text-gray-700">Top Products</h2>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 text-left text-gray-500">
              <th className="pb-2 font-medium">Product</th>
              <th className="pb-2 font-medium">Quantity Sold</th>
            </tr>
          </thead>
          <tbody>
            {stats.top_products.map((p) => (
              <tr key={p.name} className="border-b border-gray-100 last:border-0">
                <td className="py-2">{p.name}</td>
                <td className="py-2">{p.quantity}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
