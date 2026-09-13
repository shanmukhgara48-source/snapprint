import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link } from "../../components/Link";
import { api } from "../../lib/api";
import type { ReturnRequest } from "../../lib/types";
import { Badge, Button, Card, EmptyState, Modal, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";

const statusTone: Record<string, "neutral" | "success" | "warning" | "danger" | "info"> = {
  requested: "warning",
  approved: "info",
  rejected: "neutral",
  refunded: "success",
};

const REASONS: Record<string, string> = {
  damaged: "Damaged",
  wrong_item: "Wrong item",
  quality_issue: "Quality issue",
  late_delivery: "Late delivery",
  changed_mind: "Changed mind",
  other: "Other",
};

export default function Returns() {
  const qc = useQueryClient();
  const [status, setStatus] = useState("");
  const [decide, setDecide] = useState<ReturnRequest | null>(null);
  const [note, setNote] = useState("");
  const [msg, setMsg] = useState<string | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["returns", status],
    queryFn: async () =>
      (await api.get<ReturnRequest[]>("/admin/returns", { params: status ? { status } : {} })).data,
  });

  const decideMut = useMutation({
    mutationFn: ({ id, action, admin_note }: { id: string; action: string; admin_note?: string }) =>
      api.patch(`/admin/returns/${id}`, { action, admin_note }),
    onSuccess: (res) => {
      setMsg(`Return ${res.data.status}.`);
      setDecide(null);
      setNote("");
      qc.invalidateQueries({ queryKey: ["returns"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      qc.invalidateQueries({ queryKey: ["orders"] });
    },
    onError: (err: unknown) => {
      const detail = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail;
      setMsg(detail ?? "Decision failed.");
    },
  });

  function openDecide(r: ReturnRequest) {
    setDecide(r);
    setNote(r.admin_note ?? "");
    setMsg(null);
  }

  return (
    <div>
      <PageHeader
        title="Returns"
        subtitle="Return requests (RMA) — approve, reject, or refund. Wired to /admin/returns"
        action={
          <select
            value={status}
            onChange={(e) => setStatus(e.target.value)}
            className="rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
          >
            <option value="">All statuses</option>
            <option value="requested">Requested</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
            <option value="refunded">Refunded</option>
          </select>
        }
      />
      {msg && <p className="mb-3 text-xs text-neutral-400">{msg}</p>}
      {isLoading ? (
        <Spinner />
      ) : !data || data.length === 0 ? (
        <Card><EmptyState message="No return requests." /></Card>
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Order</Th>
              <Th>Customer</Th>
              <Th>Reason</Th>
              <Th>Total</Th>
              <Th>Status</Th>
              <Th>Requested</Th>
              <Th>Actions</Th>
            </tr>
          </thead>
          <tbody>
            {data.map((r) => (
              <tr key={r.id}>
                <Td>
                  <Link to={`/orders/${r.order_id}`} className="text-accent hover:underline">
                    #{r.order_id.slice(0, 8)}
                  </Link>
                  <div className="text-xs text-neutral-500">{r.order_status} · {r.item_count} items</div>
                </Td>
                <Td>{r.customer_phone ?? "—"}</Td>
                <Td>
                  <div className="text-sm">{REASONS[r.reason] ?? r.reason}</div>
                  {r.details && <div className="max-w-xs truncate text-xs text-neutral-500">{r.details}</div>}
                </Td>
                <Td>₹{r.order_total}</Td>
                <Td><Badge tone={statusTone[r.status] ?? "neutral"}>{r.status}</Badge></Td>
                <Td className="text-xs">{new Date(r.created_at).toLocaleString()}</Td>
                <Td>
                  {(r.status === "requested" || r.status === "approved") ? (
                    <Button variant="secondary" onClick={() => openDecide(r)}>
                      Decide
                    </Button>
                  ) : (
                    <span className="text-xs text-neutral-500">{r.decided_at ? new Date(r.decided_at).toLocaleDateString() : "—"}</span>
                  )}
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}

      <Modal open={!!decide} onClose={() => setDecide(null)} title={`Return for order #${decide?.order_id.slice(0, 8)}`}>
        {decide && (
          <div className="space-y-3">
            <p className="text-sm text-neutral-300">
              {REASONS[decide.reason] ?? decide.reason} — ₹{decide.order_total} ({decide.order_status})
            </p>
            {decide.details && <p className="text-xs text-neutral-500">“{decide.details}”</p>}
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Note for the customer (required to reject)…"
              rows={3}
              className="w-full rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white placeholder:text-neutral-500"
            />
            <div className="flex flex-wrap gap-2">
              <Button
                variant="secondary"
                disabled={decideMut.isPending}
                onClick={() => decideMut.mutate({ id: decide.id, action: "approve", admin_note: note || undefined })}
              >
                Approve return
              </Button>
              <Button
                variant="secondary"
                disabled={decideMut.isPending || !note.trim()}
                onClick={() => decideMut.mutate({ id: decide.id, action: "reject", admin_note: note.trim() })}
              >
                Reject
              </Button>
              <Button
                variant="danger"
                disabled={decideMut.isPending}
                onClick={() => {
                  if (confirm(`Refund ₹${decide.order_total} and cancel this order? Stock will be restored.`)) {
                    decideMut.mutate({ id: decide.id, action: "refund", admin_note: note || undefined });
                  }
                }}
              >
                {decideMut.isPending ? "Working…" : "Refund + close order"}
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
