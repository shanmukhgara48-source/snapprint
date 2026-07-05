import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { AdminUserRecord } from "../../lib/types";
import { Badge, Button, Card, Input, Modal, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { useAuth } from "../../lib/auth";
import { Plus } from "lucide-react";

const ROLES = ["super_admin", "manager", "support_staff", "printing_staff", "delivery_staff"];
const emptyForm = { username: "", password: "", role: "support_staff" };

export default function Admins() {
  const { role: myRole } = useAuth();
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState(emptyForm);

  const { data, isLoading } = useQuery({
    queryKey: ["admins"],
    queryFn: async () => (await api.get<AdminUserRecord[]>("/admin/admins")).data,
    enabled: myRole === "super_admin",
  });

  const createMut = useMutation({
    mutationFn: () => api.post("/admin/admins", form),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admins"] });
      setModalOpen(false);
      setForm(emptyForm);
    },
  });

  const toggleMut = useMutation({
    mutationFn: ({ id, is_active }: { id: string; is_active: boolean }) => api.patch(`/admin/admins/${id}`, { is_active }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admins"] }),
  });

  if (myRole !== "super_admin") {
    return (
      <div>
        <PageHeader title="Employees" />
        <Card>
          <p className="text-sm text-neutral-400">Only super_admin can manage employee accounts.</p>
        </Card>
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title="Employees"
        subtitle="Admin users & roles — wired to /admin/admins"
        action={
          <Button onClick={() => setModalOpen(true)}>
            <Plus size={16} /> Add employee
          </Button>
        }
      />

      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Username</Th>
              <Th>Role</Th>
              <Th>Status</Th>
              <Th>Last login</Th>
              <Th>Actions</Th>
            </tr>
          </thead>
          <tbody>
            {data?.map((a) => (
              <tr key={a.id}>
                <Td>{a.username}</Td>
                <Td className="capitalize">{a.role.replace("_", " ")}</Td>
                <Td>
                  <Badge tone={a.is_active ? "success" : "danger"}>{a.is_active ? "Active" : "Disabled"}</Badge>
                </Td>
                <Td>{a.last_login_at ? new Date(a.last_login_at).toLocaleString() : "Never"}</Td>
                <Td>
                  <button
                    onClick={() => toggleMut.mutate({ id: a.id, is_active: !a.is_active })}
                    className="text-xs text-neutral-400 hover:text-white"
                  >
                    {a.is_active ? "Disable" : "Enable"}
                  </button>
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="New employee">
        <div className="space-y-3">
          <Input placeholder="Username" value={form.username} onChange={(e) => setForm({ ...form, username: e.target.value })} />
          <Input
            placeholder="Password"
            type="password"
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
          />
          <select
            value={form.role}
            onChange={(e) => setForm({ ...form, role: e.target.value })}
            className="w-full rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
          >
            {ROLES.map((r) => (
              <option key={r} value={r}>
                {r.replace("_", " ")}
              </option>
            ))}
          </select>
          <Button onClick={() => createMut.mutate()} className="w-full justify-center" disabled={createMut.isPending}>
            Create
          </Button>
        </div>
      </Modal>
    </div>
  );
}
