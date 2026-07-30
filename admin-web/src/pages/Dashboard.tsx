import { useQuery } from "@tanstack/react-query";
import { api } from "../lib/api";
import type { DashboardAnalytics, ChartsAnalytics } from "../lib/types";
import { Card, ErrorState, PageHeader, Spinner } from "../components/ui";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from "recharts";

function money(n: number) {
  return `₹${n.toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;
}

export default function Dashboard() {
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["dashboard"],
    queryFn: async () => (await api.get<DashboardAnalytics>("/admin/analytics/dashboard")).data,
  });
  const { data: charts } = useQuery({
    queryKey: ["dashboard-charts"],
    queryFn: async () => (await api.get<ChartsAnalytics>("/admin/analytics/charts", { params: { days: 30 } })).data,
  });

  if (isLoading) return <Spinner />;
  if (isError || !data) return <ErrorState message="Failed to load dashboard analytics." onRetry={() => refetch()} />;

  const kpis = [
    { label: "Revenue today", value: money(data.revenue.today) },
    { label: "Revenue this week", value: money(data.revenue.week) },
    { label: "Revenue this month", value: money(data.revenue.month) },
    { label: "Orders today", value: data.orders.today },
    { label: "Total customers", value: data.users.total },
    { label: "New customers (mo)", value: data.users.new_this_month },
    { label: "Failed payments", value: data.payments.failed },
    { label: "Photos uploaded", value: data.photos.total_uploaded },
  ];

  return (
    <div>
      <PageHeader title="Dashboard" subtitle="Live from /admin/analytics" />
      <div className="grid grid-cols-4 gap-4 mb-6">
        {kpis.map((k) => (
          <Card key={k.label}>
            <div className="text-xs text-neutral-400">{k.label}</div>
            <div className="mt-1 text-2xl font-semibold text-white">{k.value}</div>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-4 mb-6">
        <Card>
          <div className="mb-3 text-sm font-medium text-white">Orders by status</div>
          <div className="space-y-2">
            {Object.entries(data.orders.by_status).map(([status, count]) => (
              <div key={status} className="flex items-center justify-between text-sm">
                <span className="capitalize text-neutral-300">{status}</span>
                <span className="text-neutral-400">{count}</span>
              </div>
            ))}
          </div>
        </Card>
        <Card>
          <div className="mb-3 text-sm font-medium text-white">Top products</div>
          <div className="space-y-2">
            {data.top_products.map((p) => (
              <div key={p.name} className="flex items-center justify-between text-sm">
                <span className="text-neutral-300">{p.name}</span>
                <span className="text-neutral-400">{p.quantity} sold</span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {charts && (
        <Card>
          <div className="mb-3 text-sm font-medium text-white">Revenue — last 30 days</div>
          <ResponsiveContainer width="100%" height={260}>
            <LineChart data={charts.revenue}>
              <CartesianGrid strokeDasharray="3 3" stroke="#262b33" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: "#8b8f98" }} />
              <YAxis tick={{ fontSize: 11, fill: "#8b8f98" }} />
              <Tooltip contentStyle={{ background: "#14171c", border: "1px solid #262b33" }} />
              <Line type="monotone" dataKey="revenue" stroke="#eab308" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </Card>
      )}
    </div>
  );
}
