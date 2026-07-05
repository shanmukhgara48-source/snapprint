import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { api } from "../../lib/api";
import type { UserListItem } from "../../lib/types";
import { Badge, Card, Input, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";

export default function CustomersList() {
  const [role, setRole] = useState("");
  const [q, setQ] = useState("");

  const { data, isLoading } = useQuery({
    queryKey: ["users", role, q],
    queryFn: async () =>
      (await api.get<UserListItem[]>("/admin/users", { params: { role: role || undefined, q: q || undefined } })).data,
  });

  return (
    <div>
      <PageHeader title="Customers" subtitle="Wired to /admin/users" />
      <Card className="mb-4 flex gap-3 p-3">
        <Input placeholder="Search by phone…" value={q} onChange={(e) => setQ(e.target.value)} className="max-w-xs" />
        <select
          value={role}
          onChange={(e) => setRole(e.target.value)}
          className="rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
        >
          <option value="">All roles</option>
          <option value="customer">Customer</option>
          <option value="delivery">Delivery partner</option>
        </select>
      </Card>

      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Phone</Th>
              <Th>Role</Th>
              <Th>Status</Th>
              <Th>Joined</Th>
            </tr>
          </thead>
          <tbody>
            {data?.map((u) => (
              <tr key={u.id}>
                <Td>
                  <Link to={`/customers/${u.id}`} className="text-accent hover:underline">
                    {u.phone}
                  </Link>
                </Td>
                <Td className="capitalize">{u.role}</Td>
                <Td>
                  <Badge tone={u.is_active ? "success" : "danger"}>{u.is_active ? "Active" : "Suspended"}</Badge>
                </Td>
                <Td>{new Date(u.created_at).toLocaleDateString()}</Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </div>
  );
}
