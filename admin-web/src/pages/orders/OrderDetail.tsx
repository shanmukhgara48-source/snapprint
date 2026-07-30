import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useParams, Link } from "react-router-dom";
import { api } from "../../lib/api";
import type { OrderDetail as OrderDetailType, UserListItem } from "../../lib/types";
import { Badge, Button, Card, ErrorState, PageHeader, Spinner } from "../../components/ui";
import { ArrowLeft } from "lucide-react";

// Must match backend/app/routers/delivery.py VALID_STATUS_TRANSITIONS + "cancelled".
const STATUS_OPTIONS = ["confirmed", "picked_up", "out_for_delivery", "delivered", "cancelled"];

export default function OrderDetail() {
  const { id } = useParams<{ id: string }>();
  const qc = useQueryClient();
  const [notes, setNotes] = useState("");
  const [status, setStatus] = useState("");
  const [assignId, setAssignId] = useState("");
  const syncedOrderId = useRef<string | null>(null);

  const { data: order, isLoading, isError, refetch } = useQuery({
    queryKey: ["order", id],
    queryFn: async () => (await api.get<OrderDetailType>(`/admin/orders/${id}`)).data,
  });

  // Sync local edit state from the fetched order exactly once per order (by id),
  // so realtime refetches don't clobber in-progress edits, but a fresh order load does.
  useEffect(() => {
    if (order && syncedOrderId.current !== order.id) {
      setNotes(order.notes ?? "");
      setStatus(order.status);
      syncedOrderId.current = order.id;
    }
  }, [order]);

  const { data: partners } = useQuery({
    queryKey: ["delivery-partners"],
    queryFn: async () => (await api.get<UserListItem[]>("/admin/delivery-partners")).data,
  });

  const updateMut = useMutation({
    mutationFn: (payload: { status?: string; notes?: string }) => api.patch(`/admin/orders/${id}`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["order", id] }),
  });

  const assignMut = useMutation({
    mutationFn: (delivery_partner_id: string) => api.post(`/admin/orders/${id}/assign`, { delivery_partner_id }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["order", id] }),
  });

  if (isLoading) return <Spinner />;
  if (isError || !order) return <ErrorState message="Failed to load order." onRetry={() => refetch()} />;

  return (
    <div>
      <Link to="/orders" className="mb-4 inline-flex items-center gap-1.5 text-sm text-neutral-400 hover:text-white">
        <ArrowLeft size={15} /> Back to orders
      </Link>
      <PageHeader
        title={`Order #${order.id.slice(0, 8)}`}
        subtitle={`Placed ${new Date(order.created_at).toLocaleString()}`}
        action={<Badge tone="info">{order.status}</Badge>}
      />

      <div className="grid grid-cols-3 gap-4">
        <div className="col-span-2 space-y-4">
          <Card>
            <div className="mb-3 text-sm font-medium text-white">Items</div>
            <div className="divide-y divide-border">
              {order.items.map((item) => (
                <div key={item.id} className="flex items-center justify-between py-2 text-sm">
                  <div>
                    <div className="text-neutral-200">{item.product_name ?? "Custom item"}</div>
                    <div className="text-xs text-neutral-500">
                      {item.selected_size ?? "—"} × {item.quantity}
                    </div>
                  </div>
                  <div className="text-neutral-300">₹{item.unit_price}</div>
                </div>
              ))}
            </div>
          </Card>

          <Card>
            <div className="mb-3 text-sm font-medium text-white">Delivery timeline</div>
            <div className="space-y-2">
              {order.timeline.map((t, i) => (
                <div key={i} className="flex items-center justify-between text-sm">
                  <span className="capitalize text-neutral-300">{t.status}</span>
                  <span className="text-neutral-500">{new Date(t.timestamp).toLocaleString()}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>

        <div className="space-y-4">
          <Card>
            <div className="mb-2 text-xs text-neutral-500">Customer</div>
            <div className="mb-3 text-sm text-white">{order.customer_phone ?? "—"}</div>
            <div className="mb-2 text-xs text-neutral-500">Address</div>
            <div className="mb-3 text-sm text-neutral-300">{order.address ?? "—"}</div>
            <div className="mb-2 text-xs text-neutral-500">Total</div>
            <div className="text-sm text-white">
              ₹{order.total_price} ({order.delivery_type}, +₹{order.delivery_charge}
              {order.discount > 0 && `, -₹${order.discount} ${order.coupon_code ?? ""}`})
            </div>
          </Card>

          <Card>
            <div className="mb-2 text-xs text-neutral-500">Update status</div>
            <select
              value={status}
              onChange={(e) => {
                setStatus(e.target.value);
                updateMut.mutate({ status: e.target.value });
              }}
              className="mb-3 w-full rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
            >
              {STATUS_OPTIONS.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>

            <div className="mb-2 text-xs text-neutral-500">Assign delivery partner</div>
            <select
              value={assignId}
              onChange={(e) => setAssignId(e.target.value)}
              className="mb-2 w-full rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
            >
              <option value="">Select partner…</option>
              {partners?.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.phone}
                </option>
              ))}
            </select>
            <Button
              variant="secondary"
              className="mb-4 w-full justify-center"
              disabled={!assignId}
              onClick={() => assignMut.mutate(assignId)}
            >
              Assign
            </Button>

            <div className="mb-2 text-xs text-neutral-500">Notes</div>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="mb-2 w-full rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
              rows={3}
            />
            <Button variant="secondary" className="w-full justify-center" onClick={() => updateMut.mutate({ notes })}>
              Save notes
            </Button>
          </Card>
        </div>
      </div>
    </div>
  );
}
