import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link } from "../../components/Link";
import { api } from "../../lib/api";
import type { OrderListItem } from "../../lib/types";
import { useQueryParam } from "../../lib/search";
import { Badge, Button, Card, Input, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { Download, Printer } from "lucide-react";

const statusTone: Record<string, "neutral" | "success" | "warning" | "danger" | "info"> = {
  confirmed: "info",
  picked_up: "warning",
  out_for_delivery: "info",
  delivered: "success",
  cancelled: "danger",
};

const BULK_TARGETS = ["picked_up", "out_for_delivery", "delivered", "cancelled"];

export default function OrdersList() {
  const [urlStatus] = useQueryParam("status");
  const [urlQ] = useQueryParam("q");
  const [status, setStatus] = useState("");
  const [source, setSource] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [q, setQ] = useState("");
  const [exporting, setExporting] = useState(false);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [bulkMsg, setBulkMsg] = useState<string | null>(null);
  const qc = useQueryClient();

  // Deep links (e.g. Dashboard action center → ?status=confirmed) and the
  // header search (?q=…) land here through the URL.
  useEffect(() => {
    if (urlStatus) setStatus(urlStatus);
  }, [urlStatus]);
  useEffect(() => {
    if (urlQ) setQ(urlQ);
  }, [urlQ]);

  const filters = {
    status: status || undefined,
    source: source || undefined,
    created_from: from || undefined,
    created_to: to || undefined,
    q: q || undefined,
  };

  const { data, isLoading } = useQuery({
    queryKey: ["orders", status, source, from, to, q],
    queryFn: async () => (await api.get<OrderListItem[]>("/admin/orders", { params: filters })).data,
  });

  const bulkMut = useMutation({
    mutationFn: (target: string) =>
      api.post<{ updated: string[]; failed: { id: string; reason: string }[] }>(
        "/admin/orders/bulk-status",
        { ids: [...selected], status: target },
      ),
    onSuccess: (res) => {
      const { updated, failed } = res.data;
      setBulkMsg(
        failed.length === 0
          ? `${updated.length} order${updated.length === 1 ? "" : "s"} updated.`
          : `${updated.length} updated, ${failed.length} skipped (${failed[0]?.reason}).`,
      );
      setSelected(new Set());
      qc.invalidateQueries({ queryKey: ["orders"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
    },
    onError: () => setBulkMsg("Bulk update failed."),
  });

  // Download via axios (auth header required), then trigger a browser save.
  async function exportCsv() {
    setExporting(true);
    try {
      const res = await api.get("/admin/orders/export", {
        params: filters,
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

  function toggleSelect(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
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
      <Card className="mb-4 flex flex-wrap items-end gap-3 p-3">
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
        <select
          value={source}
          onChange={(e) => setSource(e.target.value)}
          className="rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
          aria-label="Filter by channel"
        >
          <option value="">All channels</option>
          <option value="mobile_app">Mobile app</option>
          <option value="website">Website</option>
          <option value="admin">Admin</option>
          <option value="unknown">Unknown</option>
        </select>
        <input
          type="date"
          value={from}
          onChange={(e) => setFrom(e.target.value)}
          aria-label="From date"
          className="rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
        />
        <input
          type="date"
          value={to}
          onChange={(e) => setTo(e.target.value)}
          aria-label="To date"
          className="rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
        />
        {(status || source || from || to || q) && (
          <button
            onClick={() => { setStatus(""); setSource(""); setFrom(""); setTo(""); setQ(""); }}
            className="text-xs text-neutral-400 hover:text-white"
          >
            Clear filters
          </button>
        )}
      </Card>

      {selected.size > 0 && (
        <Card className="mb-4 flex flex-wrap items-center gap-3 p-3">
          <span className="text-sm text-neutral-300">{selected.size} selected</span>
          {BULK_TARGETS.map((t) => (
            <button
              key={t}
              disabled={bulkMut.isPending}
              onClick={() => {
                if (t === "cancelled" && !confirm(`Cancel ${selected.size} order(s)? Paid orders are skipped — refund those individually.`)) return;
                setBulkMsg(null);
                bulkMut.mutate(t);
              }}
              className="text-xs text-neutral-300 hover:text-white disabled:opacity-50"
            >
              Mark {t.replaceAll("_", " ")}
            </button>
          ))}
          <button onClick={() => setSelected(new Set())} className="text-xs text-neutral-500 hover:text-white">
            Clear
          </button>
          {bulkMsg && <span className="text-xs text-neutral-400">{bulkMsg}</span>}
        </Card>
      )}
      {!selected.size && bulkMsg && <p className="mb-3 text-xs text-neutral-400">{bulkMsg}</p>}

      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>
                <input
                  type="checkbox"
                  checked={(data?.length ?? 0) > 0 && selected.size === data?.length}
                  onChange={() =>
                    setSelected((prev) =>
                      prev.size === (data?.length ?? 0) ? new Set() : new Set(data?.map((o) => o.id) ?? []),
                    )
                  }
                />
              </Th>
              <Th>Order</Th>
              <Th>Customer</Th>
              <Th>Channel</Th>
              <Th>Items</Th>
              <Th>Total</Th>
              <Th>Status</Th>
              <Th>Placed</Th>
              <Th>Slip</Th>            </tr>
          </thead>
          <tbody>
            {data?.map((o) => (
              <tr key={o.id}>
                <Td>
                  <input type="checkbox" checked={selected.has(o.id)} onChange={() => toggleSelect(o.id)} />
                </Td>
                <Td>
                  <Link to={`/orders/${o.id}`} className="text-accent hover:underline">
                    #{o.id.slice(0, 8)}
                  </Link>
                </Td>
                <Td>{o.customer_phone ?? "—"}</Td>
                <Td>
                  <Badge tone={o.source === "mobile_app" ? "info" : o.source === "website" ? "success" : "neutral"}>
                    {(o.source ?? "unknown").replaceAll("_", " ")}
                  </Badge>
                </Td>
                <Td>{o.item_count}{o.gift_wrap ? " 🎁" : ""}</Td>
                <Td>₹{o.total_price}</Td>
                <Td>
                  <Badge tone={statusTone[o.status] ?? "neutral"}>{o.status.replaceAll("_", " ")}</Badge>
                </Td>
                <Td>{new Date(o.created_at).toLocaleString()}</Td>
                <Td>
                  <Link to={`/orders/${o.id}?print=1`} className="text-neutral-400 hover:text-white" aria-label="Packing slip">
                    <Printer size={15} />
                  </Link>
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </div>
  );
}
