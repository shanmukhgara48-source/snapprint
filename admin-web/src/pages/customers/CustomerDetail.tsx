import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useParams, Link } from "react-router-dom";
import { api } from "../../lib/api";
import type { UserDetail } from "../../lib/types";
import { Badge, Button, Card, ErrorState, PageHeader, Spinner } from "../../components/ui";
import { ArrowLeft } from "lucide-react";

export default function CustomerDetail() {
  const { id } = useParams<{ id: string }>();
  const qc = useQueryClient();

  const { data: user, isLoading, isError, refetch } = useQuery({
    queryKey: ["user", id],
    queryFn: async () => (await api.get<UserDetail>(`/admin/users/${id}`)).data,
  });

  const suspendMut = useMutation({
    mutationFn: (is_active: boolean) => api.patch(`/admin/users/${id}`, { is_active }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["user", id] }),
  });

  const promoteMut = useMutation({
    mutationFn: () => api.post(`/admin/delivery-partners/${id}/promote`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["user", id] }),
  });

  const demoteMut = useMutation({
    mutationFn: () => api.post(`/admin/delivery-partners/${id}/demote`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["user", id] }),
  });

  if (isLoading) return <Spinner />;
  if (isError || !user) return <ErrorState message="Failed to load customer." onRetry={() => refetch()} />;

  return (
    <div>
      <Link to="/customers" className="mb-4 inline-flex items-center gap-1.5 text-sm text-neutral-400 hover:text-white">
        <ArrowLeft size={15} /> Back to customers
      </Link>
      <PageHeader
        title={user.phone}
        subtitle={`Joined ${new Date(user.created_at).toLocaleDateString()} · Referral code ${user.referral_code}`}
        action={<Badge tone={user.is_active ? "success" : "danger"}>{user.is_active ? "Active" : "Suspended"}</Badge>}
      />

      <div className="grid grid-cols-3 gap-4">
        <div className="col-span-2 space-y-4">
          <Card>
            <div className="mb-3 text-sm font-medium text-white">Order history</div>
            <div className="divide-y divide-border">
              {user.orders.length === 0 && <div className="py-2 text-sm text-neutral-500">No orders yet</div>}
              {user.orders.map((o) => (
                <div key={o.id} className="flex items-center justify-between py-2 text-sm">
                  <Link to={`/orders/${o.id}`} className="text-accent hover:underline">
                    #{o.id.slice(0, 8)}
                  </Link>
                  <span className="capitalize text-neutral-300">{o.status}</span>
                  <span className="text-neutral-400">₹{o.total_price}</span>
                </div>
              ))}
            </div>
          </Card>

          <Card>
            <div className="mb-3 text-sm font-medium text-white">Addresses</div>
            <div className="space-y-2">
              {user.addresses.length === 0 && <div className="text-sm text-neutral-500">No saved addresses</div>}
              {user.addresses.map((a) => (
                <div key={a.id} className="text-sm text-neutral-300">
                  {a.full_address}, {a.city} - {a.pincode} {a.is_default && <Badge tone="info">Default</Badge>}
                </div>
              ))}
            </div>
          </Card>
        </div>

        <Card className="space-y-2">
          <div className="mb-1 text-xs text-neutral-500">Role: <span className="capitalize text-neutral-300">{user.role}</span></div>
          <Button
            variant="secondary"
            className="w-full justify-center"
            onClick={() => suspendMut.mutate(!user.is_active)}
          >
            {user.is_active ? "Suspend account" : "Reactivate account"}
          </Button>
          {user.role === "customer" && (
            <Button variant="secondary" className="w-full justify-center" onClick={() => promoteMut.mutate()}>
              Promote to delivery partner
            </Button>
          )}
          {user.role === "delivery" && (
            <Button variant="secondary" className="w-full justify-center" onClick={() => demoteMut.mutate()}>
              Demote to customer
            </Button>
          )}
        </Card>
      </div>
    </div>
  );
}
