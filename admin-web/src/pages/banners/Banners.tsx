import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { Banner } from "../../lib/types";
import { Badge, Button, Input, Modal, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { Plus, Trash2, Pencil } from "lucide-react";

type BannerForm = { title: string; image_url: string; link_action: string; sort_order: string };

const emptyForm: BannerForm = { title: "", image_url: "", link_action: "", sort_order: "0" };

export default function Banners() {
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Banner | null>(null);
  const [form, setForm] = useState<BannerForm>(emptyForm);

  const { data, isLoading } = useQuery({
    queryKey: ["banners"],
    queryFn: async () => (await api.get<Banner[]>("/admin/banners")).data,
  });

  const createMut = useMutation({
    mutationFn: () =>
      api.post("/admin/banners", {
        title: form.title,
        image_url: form.image_url,
        link_action: form.link_action || null,
        sort_order: Number(form.sort_order) || 0,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["banners"] });
      closeModal();
    },
  });

  const updateMut = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: Partial<Banner> }) =>
      api.put(`/admin/banners/${id}`, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["banners"] });
      closeModal();
    },
  });

  const deleteMut = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/banners/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["banners"] }),
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

  function openEdit(b: Banner) {
    setEditing(b);
    setForm({ title: b.title, image_url: b.image_url, link_action: b.link_action ?? "", sort_order: String(b.sort_order) });
    setModalOpen(true);
  }

  function handleSave() {
    if (editing) {
      updateMut.mutate({
        id: editing.id,
        payload: {
          title: form.title,
          image_url: form.image_url,
          link_action: form.link_action || null,
          sort_order: Number(form.sort_order) || 0,
        },
      });
    } else {
      createMut.mutate();
    }
  }

  return (
    <div>
      <PageHeader
        title="Banners"
        subtitle="Full CRUD — wired to /admin/banners, appears live in the mobile app's home carousel"
        action={
          <Button onClick={openCreate}>
            <Plus size={16} /> Add banner
          </Button>
        }
      />

      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Title</Th>
              <Th>Image</Th>
              <Th>Link</Th>
              <Th>Order</Th>
              <Th>Status</Th>
              <Th>Actions</Th>
            </tr>
          </thead>
          <tbody>
            {data?.map((b) => (
              <tr key={b.id}>
                <Td>{b.title}</Td>
                <Td className="max-w-xs truncate">{b.image_url}</Td>
                <Td>{b.link_action ?? "—"}</Td>
                <Td>{b.sort_order}</Td>
                <Td>
                  <Badge tone={b.is_active ? "success" : "neutral"}>{b.is_active ? "Live" : "Hidden"}</Badge>
                </Td>
                <Td>
                  <div className="flex gap-2">
                    <button onClick={() => openEdit(b)} className="text-neutral-400 hover:text-white">
                      <Pencil size={15} />
                    </button>
                    <button
                      onClick={() => updateMut.mutate({ id: b.id, payload: { is_active: !b.is_active } })}
                      className="text-xs text-neutral-400 hover:text-white"
                    >
                      {b.is_active ? "Hide" : "Show"}
                    </button>
                    <button
                      onClick={() => confirm(`Delete ${b.title}?`) && deleteMut.mutate(b.id)}
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

      <Modal open={modalOpen} onClose={closeModal} title={editing ? "Edit banner" : "New banner"}>
        <div className="space-y-3">
          <Input placeholder="Title" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
          <Input placeholder="Image URL" value={form.image_url} onChange={(e) => setForm({ ...form, image_url: e.target.value })} />
          <Input
            placeholder="Link action (e.g. category:mugs)"
            value={form.link_action}
            onChange={(e) => setForm({ ...form, link_action: e.target.value })}
          />
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
