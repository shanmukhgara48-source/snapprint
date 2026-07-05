import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { api } from "../../lib/api";
import type { OrderListItem } from "../../lib/types";
import { Badge, Card, Input, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";

const statusTone: Record<string, "neutral" | "success" | "warning" | "danger" | "info"> = {
  confirmed: "info",
  processing: "warning",
  shipped: "info",
  delivered: "success",
  cancelled: "danger",
};

export default function OrdersList() {
  const [status, setStatus] = useState("");
  const [q, setQ] = useState("");

  const { data, isLoading } = useQuery({
    queryKey: ["orders", status, q],
    queryFn: async () =>
      (await api.get<OrderListItem[]>("/admin/orders", { params: { status: status || undefined, q: q || undefined } })).data,
  });

  return (
    <div>
      <PageHeader title="Orders" subtitle="Wired to /admin/orders" />
      <Card className="mb-4 flex gap-3 p-3">
        <Input placeholder="Search by phone…" value={q} onChange={(e) => setQ(e.target.value)} className="max-w-xs" />
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
        >
          <option value="">All statuses</option>
          <option value="confirmed">Confirmed</option>
          <option value="processing">Processing</option>
          <option value="shipped">Shipped</option>
          <option value="delivered">Delivered</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </Card>

      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Order</Th>
              <Th>Customer</Th>
              <Th>Items</Th>
              <Th>Total</Th>
              <Th>Status</Th>
              <Th>Placed</Th>
            </tr>
          </thead>
          <tbody>
            {data?.map((o) => (
              <tr key={o.id}>
                <Td>
                  <Link to={`/orders/${o.id}`} className="text-accent hover:underline">
                    #{o.id.slice(0, 8)}
                  </Link>
                </Td>
                <Td>{o.customer_phone ?? "—"}</Td>
                <Td>{o.item_count}</Td>
                <Td>₹{o.total_price}</Td>
                <Td>
                  <Badge tone={statusTone[o.status] ?? "neutral"}>{o.status}</Badge>
                </Td>
                <Td>{new Date(o.created_at).toLocaleString()}</Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </div>
  );
}
