import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../lib/api";
import type { Category } from "../lib/types";
import { Badge, Button, Input, Modal, PageHeader, Spinner, Table, Td, Th } from "../components/ui";
import { Plus, Trash2, Pencil } from "lucide-react";

type CategoryForm = { name: string; icon: string; image_url: string; sort_order: string };

const emptyForm: CategoryForm = { name: "", icon: "", image_url: "", sort_order: "0" };

export default function Categories() {
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Category | null>(null);
  const [form, setForm] = useState<CategoryForm>(emptyForm);

  const { data, isLoading } = useQuery({
    queryKey: ["categories"],
    queryFn: async () => (await api.get<Category[]>("/admin/categories")).data,
  });

  const createMut = useMutation({
    mutationFn: () =>
      api.post("/admin/categories", {
        name: form.name,
        icon: form.icon,
        image_url: form.image_url || null,
        sort_order: Number(form.sort_order) || 0,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["categories"] });
      closeModal();
    },
  });

  const updateMut = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: Partial<Category> }) =>
      api.put(`/admin/categories/${id}`, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["categories"] });
      closeModal();
    },
  });

  const deleteMut = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/categories/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["categories"] }),
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

  function openEdit(c: Category) {
    setEditing(c);
    setForm({ name: c.name, icon: c.icon, image_url: c.image_url ?? "", sort_order: String(c.sort_order) });
    setModalOpen(true);
  }

  function handleSave() {
    if (editing) {
      updateMut.mutate({
        id: editing.id,
        payload: { name: form.name, icon: form.icon, image_url: form.image_url || null, sort_order: Number(form.sort_order) || 0 },
      });
    } else {
      createMut.mutate();
    }
  }

  return (
    <div>
      <PageHeader
        title="Categories"
        subtitle="Full CRUD — wired to /admin/categories, appears live in the mobile app's category grid"
        action={
          <Button onClick={openCreate}>
            <Plus size={16} /> Add category
          </Button>
        }
      />

      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Name</Th>
              <Th>Icon</Th>
              <Th>Order</Th>
              <Th>Status</Th>
              <Th>Actions</Th>
            </tr>
          </thead>
          <tbody>
            {data?.map((c) => (
              <tr key={c.id}>
                <Td className="capitalize">{c.name}</Td>
                <Td>{c.icon}</Td>
                <Td>{c.sort_order}</Td>
                <Td>
                  <Badge tone={c.is_active ? "success" : "neutral"}>{c.is_active ? "Active" : "Hidden"}</Badge>
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
                      {c.is_active ? "Hide" : "Show"}
                    </button>
                    <button
                      onClick={() => confirm(`Delete ${c.name}?`) && deleteMut.mutate(c.id)}
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

      <Modal open={modalOpen} onClose={closeModal} title={editing ? "Edit category" : "New category"}>
        <div className="space-y-3">
          <Input placeholder="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          <Input placeholder="Icon (e.g. photo, coffee, book)" value={form.icon} onChange={(e) => setForm({ ...form, icon: e.target.value })} />
          <Input placeholder="Image URL" value={form.image_url} onChange={(e) => setForm({ ...form, image_url: e.target.value })} />
          <Input
            placeholder="Sort order"
            type="number"
            value={form.sort_order}
            onChange={(e) => setForm({ ...form, sort_order: e.target.value })}
          />
          <Button onClick={handleSave} className="w-full justify-center" disabled={createMut.isPending || updateMut.isPending}>
            Save
          </Button>
        </div>
      </Modal>
    </div>
  );
}
