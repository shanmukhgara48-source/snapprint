import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { Category, Product } from "../../lib/types";
import { Badge, Button, Card, Input, Modal, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { ImageGalleryUploader } from "../../components/ImageUpload";
import { Plus, Trash2, Pencil } from "lucide-react";

type ProductForm = {
  name: string;
  category: string;
  base_price: string;
  description: string;
  images: string;
  stock_quantity: string;
  tracks_inventory: boolean;
  is_trending: boolean;
};

const emptyForm: ProductForm = {
  name: "",
  category: "",
  base_price: "",
  description: "",
  images: "",
  stock_quantity: "0",
  tracks_inventory: false,
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
  const [selected, setSelected] = useState<Set<string>>(new Set());

  const { data, isLoading } = useQuery({
    queryKey: ["products", q],
    queryFn: async () => (await api.get<Product[]>("/admin/products", { params: q ? { q } : {} })).data,
  });

  // Categories come from the same source of truth as the Categories tab, so a
  // product's category can never drift/typo away from a real category — this
  // previously broke customer-side "tap category -> see products" browsing
  // whenever the free-text value didn't exactly match Category.name.
  const { data: categories } = useQuery({
    queryKey: ["categories"],
    queryFn: async () => (await api.get<Category[]>("/admin/categories")).data,
  });

  function categoryPayload(categoryName: string) {
    const match = categories?.find((c) => c.name === categoryName);
    return { category: categoryName, category_id: match?.id ?? null };
  }

  const createMut = useMutation({
    mutationFn: (payload: ProductForm) =>
      api.post("/admin/products", {
        name: payload.name,
        ...categoryPayload(payload.category),
        base_price: Number(payload.base_price),
        sizes: [],
        description: payload.description || null,
        images: parseImages(payload.images),
        stock_quantity: Number(payload.stock_quantity) || 0,
        tracks_inventory: payload.tracks_inventory,
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

  const bulkUpdateMut = useMutation({
    mutationFn: (update: Partial<Product>) =>
      api.post("/admin/products/bulk-update", { ids: [...selected], update }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["products"] });
      setSelected(new Set());
    },
  });

  const bulkDeleteMut = useMutation({
    mutationFn: () => api.post("/admin/products/bulk-delete", { ids: [...selected] }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["products"] });
      setSelected(new Set());
    },
  });

  function toggleSelect(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function toggleSelectAll() {
    setSelected((prev) =>
      prev.size === (data?.length ?? 0) ? new Set() : new Set(data?.map((p) => p.id) ?? []),
    );
  }

  function openCreate() {
    setEditing(null);
    setForm({ ...emptyForm, category: categories?.[0]?.name ?? "" });
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
      tracks_inventory: p.tracks_inventory ?? false,
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
          ...categoryPayload(form.category),
          base_price: Number(form.base_price),
          description: form.description || null,
          images: parseImages(form.images),
          stock_quantity: Number(form.stock_quantity) || 0,
          tracks_inventory: form.tracks_inventory,
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

      {selected.size > 0 && (
        <Card className="mb-4 flex items-center gap-3 p-3">
          <span className="text-sm text-neutral-300">{selected.size} selected</span>
          <button onClick={() => bulkUpdateMut.mutate({ is_active: true })} className="text-xs text-neutral-400 hover:text-white">Enable</button>
          <button onClick={() => bulkUpdateMut.mutate({ is_active: false })} className="text-xs text-neutral-400 hover:text-white">Disable</button>
          <button onClick={() => bulkUpdateMut.mutate({ is_trending: true })} className="text-xs text-neutral-400 hover:text-white">Trend</button>
          <button onClick={() => bulkUpdateMut.mutate({ is_trending: false })} className="text-xs text-neutral-400 hover:text-white">Untrend</button>
          <button onClick={() => bulkUpdateMut.mutate({ is_featured: true })} className="text-xs text-neutral-400 hover:text-white">Feature</button>
          <button onClick={() => bulkUpdateMut.mutate({ is_featured: false })} className="text-xs text-neutral-400 hover:text-white">Unfeature</button>
          <button
            onClick={() => confirm(`Delete ${selected.size} products?`) && bulkDeleteMut.mutate()}
            className="text-xs text-red-500 hover:text-red-400"
          >
            Delete selected
          </button>
        </Card>
      )}

      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>
                <input
                  type="checkbox"
                  checked={(data?.length ?? 0) > 0 && selected.size === data?.length}
                  onChange={toggleSelectAll}
                />
              </Th>
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
                <Td>
                  <input type="checkbox" checked={selected.has(p.id)} onChange={() => toggleSelect(p.id)} />
                </Td>
                <Td>{p.name}</Td>
                <Td className="capitalize">{p.category}</Td>
                <Td>₹{p.base_price}</Td>
                <Td>{p.tracks_inventory ? p.stock_quantity : "Unlimited"}</Td>
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
          <select
            value={form.category}
            onChange={(e) => setForm({ ...form, category: e.target.value })}
            className="w-full rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white outline-none focus:border-accent"
          >
            {!categories?.some((c) => c.name === form.category) && (
              <option value={form.category}>{form.category || "Select a category…"}</option>
            )}
            {categories?.map((c) => (
              <option key={c.id} value={c.name}>
                {c.name}
              </option>
            ))}
          </select>
          <Input
            placeholder="Base price"
            type="number"
            value={form.base_price}
            onChange={(e) => setForm({ ...form, base_price: e.target.value })}
          />
          <ImageGalleryUploader images={form.images} onChange={(next) => setForm({ ...form, images: next })} />
          <Input
            placeholder="Description"
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
          />
          <Input
            placeholder="Stock quantity"
            type="number"
            value={form.stock_quantity}
            disabled={!form.tracks_inventory}
            onChange={(e) => setForm({ ...form, stock_quantity: e.target.value })}
          />
          <label className="flex items-center gap-2 text-sm text-neutral-300">
            <input
              type="checkbox"
              checked={form.tracks_inventory}
              onChange={(e) => setForm({ ...form, tracks_inventory: e.target.checked })}
            />
            Track inventory
          </label>
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
