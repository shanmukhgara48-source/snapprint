import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { Category, Product } from "../../lib/types";
import { useQueryParam } from "../../lib/search";
import { Badge, Button, Card, Input, Modal, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { ImageGalleryUploader } from "../../components/ImageUpload";
import { Plus, Trash2, Pencil, Download } from "lucide-react";

type ProductForm = {
  name: string;
  category: string;
  base_price: string;
  description: string;
  images: string;
  stock_quantity: string;
  tracks_inventory: boolean;
  is_trending: boolean;
  is_orderable: boolean;
  sku: string;
  compare_at_price: string;
  is_bestseller: boolean;
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
  is_orderable: true,
  sku: "",
  compare_at_price: "",
  is_bestseller: false,
};

function parseImages(raw: string): string[] {
  return raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

export default function ProductsList() {
  const qc = useQueryClient();
  const [urlQ] = useQueryParam("q");
  const [q, setQ] = useState("");
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Product | null>(null);
  const [form, setForm] = useState<ProductForm>(emptyForm);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [exporting, setExporting] = useState(false);

  // Header global search (?q=…) lands here through the URL.
  useEffect(() => {
    if (urlQ) setQ(urlQ);
  }, [urlQ]);

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
        is_orderable: payload.is_orderable,
        sku: payload.sku.trim() || null,
        compare_at_price: payload.compare_at_price ? Number(payload.compare_at_price) : null,
        is_bestseller: payload.is_bestseller,
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
      is_orderable: p.is_orderable ?? true,
      sku: p.sku ?? "",
      compare_at_price: p.compare_at_price ? String(p.compare_at_price) : "",
      is_bestseller: p.is_bestseller ?? false,
    });
    setModalOpen(true);
  }

  async function exportCsv() {
    setExporting(true);
    try {
      const res = await api.get("/admin/products/export", { responseType: "blob" });
      const url = URL.createObjectURL(res.data as Blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "snapprint-inventory.csv";
      a.click();
      URL.revokeObjectURL(url);
    } finally {
      setExporting(false);
    }
  }

  function handleSave() {    if (editing) {
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
          is_orderable: form.is_orderable,
          sku: form.sku.trim() || null,
          compare_at_price: form.compare_at_price ? Number(form.compare_at_price) : null,
          is_bestseller: form.is_bestseller,
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
          <div className="flex gap-2">
            <Button variant="secondary" onClick={exportCsv} disabled={exporting}>
              <Download size={16} /> {exporting ? "Exporting…" : "Export CSV"}
            </Button>
            <Button onClick={openCreate}>
              <Plus size={16} /> Add product
            </Button>
          </div>
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
          <button onClick={() => bulkUpdateMut.mutate({ tracks_inventory: true })} className="text-xs text-neutral-400 hover:text-white">Track stock</button>
          <button onClick={() => bulkUpdateMut.mutate({ tracks_inventory: false })} className="text-xs text-neutral-400 hover:text-white">Untrack stock</button>
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
                <Td>{p.is_orderable ? `₹${p.base_price}` : "Pricing pending"}</Td>
                <Td>
                  {p.tracks_inventory ? (
                    <span className="inline-flex items-center gap-1.5">
                      <button
                        aria-label={`Decrease stock for ${p.name}`}
                        disabled={updateMut.isPending || p.stock_quantity <= 0}
                        onClick={() => updateMut.mutate({ id: p.id, payload: { stock_quantity: Math.max(0, p.stock_quantity - 1) } })}
                        className="rounded border border-border px-1.5 text-neutral-300 hover:bg-surface-2 disabled:opacity-40"
                      >
                        −
                      </button>
                      <span className={p.stock_quantity <= 5 ? "font-semibold text-red-400" : ""}>
                        {p.stock_quantity}{p.stock_quantity <= 5 ? (p.stock_quantity === 0 ? " · out" : " · low") : ""}
                      </span>
                      <button
                        aria-label={`Increase stock for ${p.name}`}
                        disabled={updateMut.isPending}
                        onClick={() => updateMut.mutate({ id: p.id, payload: { stock_quantity: p.stock_quantity + 1 } })}
                        className="rounded border border-border px-1.5 text-neutral-300 hover:bg-surface-2 disabled:opacity-40"
                      >
                        +
                      </button>
                    </span>
                  ) : (
                    "Unlimited"
                  )}
                </Td>
                <Td>
                  <div className="flex gap-1">
                    <Badge tone={p.is_active ? "success" : "neutral"}>{p.is_active ? "Active" : "Disabled"}</Badge>
                    {p.is_bestseller && <Badge tone="warning">Bestseller</Badge>}
                    {p.is_featured && <Badge tone="success">Featured</Badge>}
                    {p.is_trending && <Badge tone="success">Trending</Badge>}
                    {!p.is_orderable && <Badge tone="neutral">Catalog only</Badge>}
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
                      onClick={() => updateMut.mutate({ id: p.id, payload: { is_bestseller: !p.is_bestseller } })}
                      className="text-xs text-neutral-400 hover:text-white"
                    >
                      {p.is_bestseller ? "Unbest" : "Best"}
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
          <div className="grid grid-cols-2 gap-3">
            <Input
              placeholder="SKU (e.g. PRINT-4X6-001)"
              value={form.sku}
              onChange={(e) => setForm({ ...form, sku: e.target.value })}
            />
            <Input
              placeholder="MRP / compare-at price (strike-through)"
              type="number"
              value={form.compare_at_price}
              onChange={(e) => setForm({ ...form, compare_at_price: e.target.value })}
            />
          </div>
          <label className="flex items-center gap-2 text-sm text-neutral-300">
            <input
              type="checkbox"
              checked={form.is_bestseller}
              onChange={(e) => setForm({ ...form, is_bestseller: e.target.checked })}
            />
            Bestseller badge
          </label>
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
          <label className="flex items-center gap-2 text-sm text-neutral-300">
            <input
              type="checkbox"
              checked={form.is_orderable}
              onChange={(e) => setForm({ ...form, is_orderable: e.target.checked })}
            />
            Available to order
          </label>
          <Button onClick={handleSave} className="w-full justify-center" disabled={createMut.isPending || updateMut.isPending}>
            Save
          </Button>
        </div>
      </Modal>
    </div>
  );
}
