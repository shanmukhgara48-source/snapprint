"use client";

import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { UserDetail } from "@/lib/types";

export default function UserDetailPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const queryClient = useQueryClient();

  const { data: user, isLoading } = useQuery({
    queryKey: ["admin", "user", params.id],
    queryFn: async () => (await api.get<UserDetail>(`/admin/users/${params.id}`)).data,
  });

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ["admin", "user", params.id] });

  const toggleActiveMutation = useMutation({
    mutationFn: async (is_active: boolean) => api.patch(`/admin/users/${params.id}`, { is_active }),
    onSuccess: invalidate,
  });

  const promoteMutation = useMutation({
    mutationFn: async () => api.post(`/admin/delivery-partners/${params.id}/promote`),
    onSuccess: invalidate,
  });

  const demoteMutation = useMutation({
    mutationFn: async () => api.post(`/admin/delivery-partners/${params.id}/demote`),
    onSuccess: invalidate,
  });

  if (isLoading) return <div className="text-sm text-gray-400">Loading user...</div>;
  if (!user) return <div className="text-sm text-red-500">User not found.</div>;

  return (
    <div className="space-y-6">
      <button onClick={() => router.push("/users")} className="text-xs text-gray-500 hover:underline">
        ← Back to users
      </button>

      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">{user.phone}</h1>
          <p className="text-sm text-gray-500">
            {user.role} · joined {new Date(user.created_at).toLocaleDateString()}
          </p>
        </div>
        <div className="flex gap-2">
          {user.role === "customer" && (
            <button
              onClick={() => promoteMutation.mutate()}
              className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50"
            >
              Promote to Delivery Partner
            </button>
          )}
          {user.role === "delivery" && (
            <button
              onClick={() => demoteMutation.mutate()}
              className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50"
            >
              Demote to Customer
            </button>
          )}
          <button
            onClick={() => toggleActiveMutation.mutate(!user.is_active)}
            className={`rounded-md px-3 py-2 text-sm text-white ${user.is_active ? "bg-red-600 hover:bg-red-700" : "bg-green-600 hover:bg-green-700"}`}
          >
            {user.is_active ? "Suspend" : "Reactivate"}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="mb-3 text-sm font-semibold text-gray-700">Addresses</h2>
          {user.addresses.length === 0 && <p className="text-sm text-gray-400">No addresses saved.</p>}
          <ul className="space-y-2 text-sm">
            {user.addresses.map((a) => (
              <li key={a.id} className="border-t border-gray-100 pt-2 first:border-0 first:pt-0">
                {a.full_address}, {a.city} - {a.pincode}
                {a.is_default && <span className="ml-2 rounded-full bg-gray-100 px-2 py-0.5 text-xs">Default</span>}
              </li>
            ))}
          </ul>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="mb-3 text-sm font-semibold text-gray-700">Order History</h2>
          {user.orders.length === 0 && <p className="text-sm text-gray-400">No orders yet.</p>}
          <ul className="space-y-2 text-sm">
            {user.orders.map((o) => (
              <li key={o.id} className="flex justify-between border-t border-gray-100 pt-2 first:border-0 first:pt-0">
                <span className="capitalize">{o.status.replace("_", " ")}</span>
                <span>₹{o.total_price.toFixed(2)}</span>
                <span className="text-gray-500">{new Date(o.created_at).toLocaleDateString()}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}
