import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { Product } from "../../lib/types";
import { Badge, Button, Card, Input, Modal, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { Plus, Trash2, Pencil } from "lucide-react";

type ProductForm = {
  name: string;
  category: string;
  base_price: string;
  description: string;
  images: string;
  stock_quantity: string;
  is_trending: boolean;
};

const emptyForm: ProductForm = {
  name: "",
  category: "",
  base_price: "",
  description: "",
  images: "",
  stock_quantity: "0",
  is_trending: false,
};

function parseImages(raw: string): string[] {
  return raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

export default function ProductsList() {
  const qc = useQueryClient();
  const [q, setQ] = useState("");
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Product | null>(null);
  const [form, setForm] = useState<ProductForm>(emptyForm);

  const { data, isLoading } = useQuery({
    queryKey: ["products", q],
    queryFn: async () => (await api.get<Product[]>("/admin/products", { params: q ? { q } : {} })).data,
  });

  const createMut = useMutation({
    mutationFn: (payload: ProductForm) =>
      api.post("/admin/products", {
        name: payload.name,
        category: payload.category,
        base_price: Number(payload.base_price),
        sizes: [],
        description: payload.description || null,
        images: parseImages(payload.images),
        stock_quantity: Number(payload.stock_quantity) || 0,
        is_trending: payload.is_trending,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["products"] });
      setModalOpen(false);
      setForm(emptyForm);
    },
  });

  const updateMut = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: Partial<Product> }) =>
      api.put(`/admin/products/${id}`, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["products"] });
      setModalOpen(false);
      setEditing(null);
      setForm(emptyForm);
    },
  });

  const deleteMut = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/products/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["products"] }),
  });

  function openCreate() {
    setEditing(null);
    setForm(emptyForm);
    setModalOpen(true);
  }

  function openEdit(p: Product) {
    setEditing(p);
    setForm({
      name: p.name,
      category: p.category,
      base_price: String(p.base_price),
      description: p.description ?? "",
      images: (p.images ?? []).join(", "),
      stock_quantity: String(p.stock_quantity ?? 0),
      is_trending: p.is_trending ?? false,
    });
    setModalOpen(true);
  }

  function handleSave() {
    if (editing) {
      updateMut.mutate({
        id: editing.id,
        payload: {
          name: form.name,
          category: form.category,
          base_price: Number(form.base_price),
          description: form.description || null,
          images: parseImages(form.images),
          stock_quantity: Number(form.stock_quantity) || 0,
          is_trending: form.is_trending,
        },
      });
    } else {
      createMut.mutate(form);
    }
  }

  return (
    <div>
      <PageHeader
        title="Products"
        subtitle="Full CRUD — wired to /admin/products"
        action={
          <Button onClick={openCreate}>
            <Plus size={16} /> Add product
          </Button>
        }
      />
      <Card className="mb-4 p-3">
        <Input placeholder="Search by name or category…" value={q} onChange={(e) => setQ(e.target.value)} />
      </Card>

      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Name</Th>
              <Th>Category</Th>
              <Th>Base price</Th>
              <Th>Stock</Th>
              <Th>Status</Th>
              <Th>Actions</Th>
            </tr>
          </thead>
          <tbody>
            {data?.map((p) => (
              <tr key={p.id}>
                <Td>{p.name}</Td>
                <Td className="capitalize">{p.category}</Td>
                <Td>₹{p.base_price}</Td>
                <Td>{p.stock_quantity}</Td>
                <Td>
                  <div className="flex gap-1">
                    <Badge tone={p.is_active ? "success" : "neutral"}>{p.is_active ? "Active" : "Disabled"}</Badge>
                    {p.is_featured && <Badge tone="success">Featured</Badge>}
                    {p.is_trending && <Badge tone="success">Trending</Badge>}
                  </div>
                </Td>
                <Td>
                  <div className="flex gap-2">
                    <button onClick={() => openEdit(p)} className="text-neutral-400 hover:text-white">
                      <Pencil size={15} />
                    </button>
                    <button
                      onClick={() => updateMut.mutate({ id: p.id, payload: { is_active: !p.is_active } })}
                      className="text-xs text-neutral-400 hover:text-white"
                    >
                      {p.is_active ? "Disable" : "Enable"}
                    </button>
                    <button
                      onClick={() => updateMut.mutate({ id: p.id, payload: { is_trending: !p.is_trending } })}
                      className="text-xs text-neutral-400 hover:text-white"
                    >
                      {p.is_trending ? "Untrend" : "Trend"}
                    </button>
                    <button
                      onClick={() => confirm(`Delete ${p.name}?`) && deleteMut.mutate(p.id)}
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

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={editing ? "Edit product" : "New product"}>
        <div className="space-y-3">
          <Input placeholder="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          <Input
            placeholder="Category"
            value={form.category}
            onChange={(e) => setForm({ ...form, category: e.target.value })}
          />
          <Input
            placeholder="Base price"
            type="number"
            value={form.base_price}
            onChange={(e) => setForm({ ...form, base_price: e.target.value })}
          />
          <Input
            placeholder="Image URLs (comma-separated)"
            value={form.images}
            onChange={(e) => setForm({ ...form, images: e.target.value })}
          />
          <Input
            placeholder="Description"
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
          />
          <Input
            placeholder="Stock quantity"
            type="number"
            value={form.stock_quantity}
            onChange={(e) => setForm({ ...form, stock_quantity: e.target.value })}
          />
          <label className="flex items-center gap-2 text-sm text-neutral-300">
            <input
              type="checkbox"
              checked={form.is_trending}
              onChange={(e) => setForm({ ...form, is_trending: e.target.checked })}
            />
            Trending
          </label>
          <Button onClick={handleSave} className="w-full justify-center" disabled={createMut.isPending || updateMut.isPending}>
            Save
          </Button>
        </div>
      </Modal>
    </div>
  );
}
