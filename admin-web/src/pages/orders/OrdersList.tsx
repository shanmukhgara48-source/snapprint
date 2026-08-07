import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link } from "../../components/Link";
import { api } from "../../lib/api";
import type { OrderListItem } from "../../lib/types";
import { Badge, Button, Card, Input, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { Download } from "lucide-react";

const statusTone: Record<string, "neutral" | "success" | "warning" | "danger" | "info"> = {
  confirmed: "info",
  picked_up: "warning",
  out_for_delivery: "info",
  delivered: "success",
  cancelled: "danger",
};

export default function OrdersList() {
  const [status, setStatus] = useState("");
  const [q, setQ] = useState("");
  const [exporting, setExporting] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ["orders", status, q],
    queryFn: async () =>
      (await api.get<OrderListItem[]>("/admin/orders", { params: { status: status || undefined, q: q || undefined } })).data,
  });

  // Download via axios (auth header required), then trigger a browser save.
  async function exportCsv() {
    setExporting(true);
    try {
      const res = await api.get("/admin/orders/export", {
        params: { status: status || undefined },
        responseType: "blob",
      });
      const url = URL.createObjectURL(res.data as Blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `snapprint-orders${status ? `-${status}` : ""}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } finally {
      setExporting(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Orders"
        subtitle="Wired to /admin/orders"
        action={
          <Button onClick={exportCsv} disabled={exporting}>
            <Download size={16} /> {exporting ? "Exporting…" : "Export CSV"}
          </Button>
        }
      />
      <Card className="mb-4 flex gap-3 p-3">
        <Input placeholder="Search by phone…" value={q} onChange={(e) => setQ(e.target.value)} className="max-w-xs" />
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
        >
          <option value="">All statuses</option>
          <option value="confirmed">Confirmed</option>
          <option value="picked_up">Picked up</option>
          <option value="out_for_delivery">Out for delivery</option>
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
                  <Badge tone={statusTone[o.status] ?? "neutral"}>{o.status.replaceAll("_", " ")}</Badge>
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
