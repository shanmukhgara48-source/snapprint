import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { Coupon } from "../../lib/types";
import { Badge, Button, Input, Modal, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { Plus, Trash2, Pencil } from "lucide-react";

const emptyForm = { code: "", discount_type: "percent", value: "", min_order: "0", max_uses: "" };

export default function Coupons() {
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Coupon | null>(null);
  const [form, setForm] = useState(emptyForm);

  const { data, isLoading } = useQuery({
    queryKey: ["coupons"],
    queryFn: async () => (await api.get<Coupon[]>("/admin/coupons")).data,
  });

  const createMut = useMutation({
    mutationFn: () =>
      api.post("/admin/coupons", {
        code: form.code.toUpperCase(),
        discount_type: form.discount_type,
        value: Number(form.value),
        min_order: Number(form.min_order),
        max_uses: form.max_uses ? Number(form.max_uses) : null,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["coupons"] });
      closeModal();
    },
  });

  const updateMut = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: Partial<Coupon> }) =>
      api.put(`/admin/coupons/${id}`, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["coupons"] });
      closeModal();
    },
  });

  const deleteMut = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/coupons/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["coupons"] }),
  });

  function closeModal() {
    setModalOpen(false);
    setEditing(null);
    setForm(emptyForm);
  }

  function openCreate() {
    setEditing(null);
    setForm(emptyForm);
    setModalOpen(true);
  }

  function openEdit(c: Coupon) {
    setEditing(c);
    setForm({
      code: c.code,
      discount_type: c.discount_type,
      value: String(c.value),
      min_order: String(c.min_order),
      max_uses: c.max_uses != null ? String(c.max_uses) : "",
    });
    setModalOpen(true);
  }

  function handleSave() {
    if (editing) {
      updateMut.mutate({
        id: editing.id,
        payload: {
          discount_type: form.discount_type as "percent" | "flat",
          value: Number(form.value),
          min_order: Number(form.min_order),
          max_uses: form.max_uses ? Number(form.max_uses) : null,
        },
      });
    } else {
      createMut.mutate();
    }
  }

  return (
    <div>
      <PageHeader
        title="Offers & Coupons"
        subtitle="Full CRUD — wired to /admin/coupons; active coupons appear as Offers in the mobile app"
        action={
          <Button onClick={openCreate}>
            <Plus size={16} /> New offer
          </Button>
        }
      />

      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Code</Th>
              <Th>Discount</Th>
              <Th>Min order</Th>
              <Th>Usage</Th>
              <Th>Status</Th>
              <Th>Actions</Th>
            </tr>
          </thead>
          <tbody>
            {data?.map((c) => (
              <tr key={c.id}>
                <Td className="font-mono">{c.code}</Td>
                <Td>{c.discount_type === "percent" ? `${c.value}%` : `₹${c.value}`}</Td>
                <Td>₹{c.min_order}</Td>
                <Td>
                  {c.used_count}/{c.max_uses ?? "∞"}
                </Td>
                <Td>
                  <Badge tone={c.is_active ? "success" : "neutral"}>{c.is_active ? "Active" : "Inactive"}</Badge>
                </Td>
                <Td>
                  <div className="flex gap-2">
                    <button onClick={() => openEdit(c)} className="text-neutral-400 hover:text-white">
                      <Pencil size={15} />
                    </button>
                    <button
                      onClick={() => updateMut.mutate({ id: c.id, payload: { is_active: !c.is_active } })}
                      className="text-xs text-neutral-400 hover:text-white"
                    >
                      {c.is_active ? "Disable" : "Enable"}
                    </button>
                    <button
                      onClick={() => confirm(`Delete ${c.code}?`) && deleteMut.mutate(c.id)}
                      className="text-red-500 hover:text-red-400"
                    >
                      <Trash2 size={15} />
                    </button>
                  </div>
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}

      <Modal open={modalOpen} onClose={closeModal} title={editing ? "Edit offer" : "New offer"}>
        <div className="space-y-3">
          <Input
            placeholder="Code (e.g. SAVE20)"
            value={form.code}
            disabled={!!editing}
            onChange={(e) => setForm({ ...form, code: e.target.value })}
          />
          <select
            value={form.discount_type}
            onChange={(e) => setForm({ ...form, discount_type: e.target.value })}
            className="w-full rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
          >
            <option value="percent">Percent off</option>
            <option value="flat">Flat amount off</option>
          </select>
          <Input placeholder="Value" type="number" value={form.value} onChange={(e) => setForm({ ...form, value: e.target.value })} />
          <Input
            placeholder="Minimum order (₹)"
            type="number"
            value={form.min_order}
            onChange={(e) => setForm({ ...form, min_order: e.target.value })}
          />
          <Input
            placeholder="Max uses (blank = unlimited)"
            type="number"
            value={form.max_uses}
            onChange={(e) => setForm({ ...form, max_uses: e.target.value })}
          />
          <Button onClick={handleSave} className="w-full justify-center" disabled={createMut.isPending || updateMut.isPending}>
            Save
          </Button>
        </div>
      </Modal>
    </div>
  );
}
