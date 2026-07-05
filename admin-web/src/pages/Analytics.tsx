import { useQuery } from "@tanstack/react-query";
import { api } from "../lib/api";
import type { ChartsAnalytics } from "../lib/types";
import { Card, PageHeader, Spinner } from "../components/ui";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from "recharts";

export default function Analytics() {
  const { data, isLoading } = useQuery({
    queryKey: ["analytics-charts"],
    queryFn: async () => (await api.get<ChartsAnalytics>("/admin/analytics/charts", { params: { days: 30 } })).data,
  });

  if (isLoading || !data) return <Spinner />;

  return (
    <div>
      <PageHeader title="Analytics" subtitle="30-day trends — wired to /admin/analytics/charts" />
      <div className="space-y-4">
        <Card>
          <div className="mb-3 text-sm font-medium text-white">Revenue</div>
          <ResponsiveContainer width="100%" height={240}>
            <LineChart data={data.revenue}>
              <CartesianGrid strokeDasharray="3 3" stroke="#262b33" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: "#8b8f98" }} />
              <YAxis tick={{ fontSize: 11, fill: "#8b8f98" }} />
              <Tooltip contentStyle={{ background: "#14171c", border: "1px solid #262b33" }} />
              <Line type="monotone" dataKey="revenue" stroke="#eab308" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </Card>
        <Card>
          <div className="mb-3 text-sm font-medium text-white">Orders</div>
          <ResponsiveContainer width="100%" height={240}>
            <LineChart data={data.orders}>
              <CartesianGrid strokeDasharray="3 3" stroke="#262b33" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: "#8b8f98" }} />
              <YAxis tick={{ fontSize: 11, fill: "#8b8f98" }} />
              <Tooltip contentStyle={{ background: "#14171c", border: "1px solid #262b33" }} />
              <Line type="monotone" dataKey="orders" stroke="#60a5fa" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </Card>
        <Card>
          <div className="mb-3 text-sm font-medium text-white">New users</div>
          <ResponsiveContainer width="100%" height={240}>
            <LineChart data={data.users}>
              <CartesianGrid strokeDasharray="3 3" stroke="#262b33" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: "#8b8f98" }} />
              <YAxis tick={{ fontSize: 11, fill: "#8b8f98" }} />
              <Tooltip contentStyle={{ background: "#14171c", border: "1px solid #262b33" }} />
              <Line type="monotone" dataKey="new_users" stroke="#4ade80" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </Card>
      </div>
    </div>
  );
}
