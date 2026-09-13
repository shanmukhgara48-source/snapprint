import { useQuery } from "@tanstack/react-query";
import { api } from "../lib/api";
import type { DashboardAnalytics, ChartsAnalytics } from "../lib/types";
import { Card, ErrorState, PageHeader, Spinner } from "../components/ui";
import { Link } from "../components/Link";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from "recharts";
import { AlertTriangle, PackageX, ClipboardList, Inbox, CreditCard, Undo2 } from "lucide-react";

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
    { label: "Avg order value (30d)", value: money(data.sales_30d?.avg_order_value ?? 0) },
    { label: "Units sold (30d)", value: data.sales_30d?.units ?? 0 },
    { label: "Refunds (30d)", value: `${data.refunds_30d?.count ?? 0} · ${money(data.refunds_30d?.amount ?? 0)}` },
    { label: "Total customers", value: data.users.total },
    { label: "New customers (mo)", value: data.users.new_this_month },
    { label: "Failed payments", value: data.alerts?.failed_payments ?? data.payments.failed },
    { label: "Photos uploaded", value: data.photos.total_uploaded },
  ];

  const alerts = [
    {
      icon: PackageX,
      label: "Out of stock",
      count: data.alerts?.out_of_stock ?? 0,
      to: "/products",
      tone: "text-red-400",
    },
    {
      icon: AlertTriangle,
      label: "Low stock (≤ 5)",
      count: data.alerts?.low_stock ?? 0,
      to: "/products",
      tone: "text-yellow-400",
    },
    {
      icon: ClipboardList,
      label: "Awaiting fulfilment",
      count: data.alerts?.awaiting_fulfilment ?? 0,
      to: "/orders?status=confirmed",
      tone: "text-blue-400",
    },
    {
      icon: Inbox,
      label: "Unread inbox",
      count: data.alerts?.inbox_unread ?? 0,
      to: "/inbox",
      tone: "text-violet-400",
    },
    {
      icon: Undo2,
      label: "Open returns",
      count: data.alerts?.open_returns ?? 0,
      to: "/returns",
      tone: "text-pink-400",
    },
    {
      icon: CreditCard,
      label: "Failed payments",
      count: data.alerts?.failed_payments ?? 0,
      to: "/payments",
      tone: "text-orange-400",
    },
  ];
  const critical = alerts.filter((a) => a.count > 0);

  return (
    <div>
      <PageHeader title="Dashboard" subtitle="Live from /admin/analytics" />

      {critical.length > 0 && (
        <Card className="mb-6 border-yellow-900/60">
          <div className="mb-3 text-sm font-medium text-white">
            Action center — {critical.length} thing{critical.length === 1 ? "" : "s"} need{critical.length === 1 ? "s" : ""} your attention
          </div>
          <div className="grid grid-cols-2 gap-3 md:grid-cols-6">
            {alerts.map((a) => (
              <Link
                key={a.label}
                to={a.to}
                className="flex items-center gap-2.5 rounded-lg border border-border bg-surface-2 px-3 py-2.5 hover:border-accent"
              >
                <a.icon size={18} className={a.tone} />
                <div>
                  <div className="text-lg font-semibold leading-none text-white">{a.count}</div>
                  <div className="mt-1 text-xs text-neutral-400">{a.label}</div>
                </div>
              </Link>
            ))}
          </div>
        </Card>
      )}

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
          <div className="mb-3 text-sm font-medium text-white">Orders by channel</div>
          <div className="space-y-2">
            {Object.entries(data.orders.by_channel ?? {}).length === 0 && (
              <div className="text-sm text-neutral-500">No channel data yet.</div>
            )}
            {Object.entries(data.orders.by_channel ?? {}).map(([channel, count]) => (
              <div key={channel} className="flex items-center justify-between text-sm">
                <span className="capitalize text-neutral-300">{channel.replaceAll("_", " ")}</span>
                <span className="text-neutral-400">{count}</span>
              </div>
            ))}
          </div>
          <div className="mt-2 text-xs text-neutral-500">
            Shared stock decrements centrally: e.g. 10 → 9 after a mobile-app sale → 8 after a website sale.
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
        <Card>
          <div className="mb-3 flex items-center justify-between">
            <div className="text-sm font-medium text-white">Live stock (tracked products)</div>
            <Link to="/products" className="text-xs text-accent hover:underline">
              Manage inventory →
            </Link>
          </div>
          <div className="space-y-2">
            {(data.low_stock ?? []).length === 0 && (
              <div className="text-sm text-neutral-500">No tracked inventory.</div>
            )}
            {(data.low_stock ?? []).map((p) => (
              <div key={p.id} className="flex items-center justify-between text-sm">
                <span className="text-neutral-300">{p.name}</span>
                <span className={p.stock_quantity <= 5 ? "text-red-400 font-semibold" : "text-neutral-400"}>
                  {p.stock_quantity} left
                </span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {data.health && (
        <Card className="mb-6">
          <div className="mb-3 flex items-center justify-between">
            <div className="text-sm font-medium text-white">Account health (30 days)</div>
            <span
              className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
                data.health.grade === "Good"
                  ? "bg-green-950 text-green-400"
                  : "bg-yellow-950 text-yellow-400"
              }`}
            >
              {data.health.grade}
            </span>
          </div>
          <div className="grid grid-cols-3 gap-4 text-sm">
            <div>
              <div className="text-xs text-neutral-400">Return rate</div>
              <div className="mt-1 text-xl font-semibold text-white">{data.health.return_rate_30d}%</div>
            </div>
            <div>
              <div className="text-xs text-neutral-400">Cancellation rate</div>
              <div className="mt-1 text-xl font-semibold text-white">{data.health.cancel_rate_30d}%</div>
            </div>
            <div>
              <div className="text-xs text-neutral-400">Avg fulfilment time</div>
              <div className="mt-1 text-xl font-semibold text-white">
                {data.health.avg_fulfilment_days} days
              </div>
            </div>
          </div>
          <div className="mt-2 text-xs text-neutral-500">
            Keep return + cancellation rates under 5% to stay in good standing — same bar as Amazon sellers.
          </div>
        </Card>
      )}

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
