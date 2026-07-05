"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Pencil, Plus, Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { exportCsv } from "@/lib/csv";
import { Product, ProductSize } from "@/lib/types";

interface ProductFormState {
  id: string | null;
  name: string;
  category: string;
  base_price: string;
  image_url: string;
  description: string;
  sizes: ProductSize[];
}

const EMPTY_FORM: ProductFormState = {
  id: null,
  name: "",
  category: "",
  base_price: "",
  image_url: "",
  description: "",
  sizes: [],
};

export default function ProductsPage() {
  const queryClient = useQueryClient();
  const [q, setQ] = useState("");
  const [form, setForm] = useState<ProductFormState | null>(null);
  const [uploading, setUploading] = useState(false);

  const { data: products, isLoading } = useQuery({
    queryKey: ["admin", "products", q],
    queryFn: async () => (await api.get<Product[]>("/admin/products", { params: q ? { q } : {} })).data,
  });

  const createMutation = useMutation({
    mutationFn: async (payload: Record<string, unknown>) => api.post("/admin/products", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "products"] });
      setForm(null);
    },
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: Record<string, unknown> }) =>
      api.put(`/admin/products/${id}`, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "products"] });
      setForm(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/admin/products/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["admin", "products"] }),
  });

  function openCreate() {
    setForm({ ...EMPTY_FORM });
  }

  function openEdit(p: Product) {
    setForm({
      id: p.id,
      name: p.name,
      category: p.category,
      base_price: String(p.base_price),
      image_url: p.image_url,
      description: p.description || "",
      sizes: p.sizes,
    });
  }

  async function handleUpload(file: File) {
    setUploading(true);
    try {
      const fd = new FormData();
      fd.append("file", file);
      const res = await api.post<{ url: string }>("/admin/upload", fd, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      setForm((f) => (f ? { ...f, image_url: res.data.url } : f));
    } finally {
      setUploading(false);
    }
  }

  function submitForm() {
    if (!form) return;
    const payload = {
      name: form.name,
      category: form.category,
      base_price: parseFloat(form.base_price),
      image_url: form.image_url,
      description: form.description || null,
      sizes: form.sizes,
    };
    if (form.id) {
      updateMutation.mutate({ id: form.id, payload });
    } else {
      createMutation.mutate(payload);
    }
  }

  function toggleActive(p: Product) {
    updateMutation.mutate({ id: p.id, payload: { is_active: !p.is_active } });
  }

  function addSize() {
    setForm((f) => (f ? { ...f, sizes: [...f.sizes, { label: "", price: 0 }] } : f));
  }

  function updateSize(idx: number, field: "label" | "price", value: string) {
    setForm((f) => {
      if (!f) return f;
      const sizes = [...f.sizes];
      sizes[idx] = { ...sizes[idx], [field]: field === "price" ? Number(value) : value };
      return { ...f, sizes };
    });
  }

  function removeSize(idx: number) {
    setForm((f) => (f ? { ...f, sizes: f.sizes.filter((_, i) => i !== idx) } : f));
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Products</h1>
          <p className="text-sm text-gray-500">Manage the product catalog</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => products && exportCsv("products.csv", products as unknown as Record<string, unknown>[])}
            className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50"
          >
            Export CSV
          </button>
          <button
            onClick={openCreate}
            className="flex items-center gap-1 rounded-md bg-gray-900 px-3 py-2 text-sm text-white hover:bg-gray-800"
          >
            <Plus size={14} /> New Product
          </button>
        </div>
      </div>

      <input
        placeholder="Search by name or category..."
        value={q}
        onChange={(e) => setQ(e.target.value)}
        className="w-full max-w-sm rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-gray-500 focus:outline-none"
      />

      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-left text-gray-500">
            <tr>
              <th className="px-4 py-2 font-medium">Image</th>
              <th className="px-4 py-2 font-medium">Name</th>
              <th className="px-4 py-2 font-medium">Category</th>
              <th className="px-4 py-2 font-medium">Base Price</th>
              <th className="px-4 py-2 font-medium">Status</th>
              <th className="px-4 py-2 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr>
                <td colSpan={6} className="px-4 py-6 text-center text-gray-400">Loading...</td>
              </tr>
            )}
            {products?.map((p) => (
              <tr key={p.id} className="border-t border-gray-100">
                <td className="px-4 py-2">
                  {p.image_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={p.image_url} alt={p.name} className="h-10 w-10 rounded object-cover" />
                  ) : (
                    <div className="h-10 w-10 rounded bg-gray-100" />
                  )}
                </td>
                <td className="px-4 py-2">{p.name}</td>
                <td className="px-4 py-2">{p.category}</td>
                <td className="px-4 py-2">₹{p.base_price.toFixed(2)}</td>
                <td className="px-4 py-2">
                  <button
                    onClick={() => toggleActive(p)}
                    className={`rounded-full px-2 py-0.5 text-xs ${
                      p.is_active ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-500"
                    }`}
                  >
                    {p.is_active ? "Active" : "Disabled"}
                  </button>
                </td>
                <td className="px-4 py-2">
                  <div className="flex gap-2">
                    <button onClick={() => openEdit(p)} className="text-gray-500 hover:text-gray-900">
                      <Pencil size={14} />
                    </button>
                    <button
                      onClick={() => {
                        if (confirm(`Delete "${p.name}"?`)) deleteMutation.mutate(p.id);
                      }}
                      className="text-gray-500 hover:text-red-600"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {!isLoading && products?.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-6 text-center text-gray-400">No products found</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {form && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4">
          <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white p-6 shadow-xl">
            <h2 className="mb-4 text-lg font-semibold">{form.id ? "Edit Product" : "New Product"}</h2>

            <label className="mb-1 block text-sm font-medium text-gray-700">Name</label>
            <input
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Category</label>
            <input
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.category}
              onChange={(e) => setForm({ ...form, category: e.target.value })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Base Price</label>
            <input
              type="number"
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.base_price}
              onChange={(e) => setForm({ ...form, base_price: e.target.value })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Description</label>
            <textarea
              className="mb-3 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
            />

            <label className="mb-1 block text-sm font-medium text-gray-700">Image</label>
            <div className="mb-3 flex items-center gap-3">
              {form.image_url && (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={form.image_url} alt="" className="h-12 w-12 rounded object-cover" />
              )}
              <input
                type="file"
                accept="image/*"
                onChange={(e) => e.target.files?.[0] && handleUpload(e.target.files[0])}
                className="text-sm"
              />
              {uploading && <span className="text-xs text-gray-400">Uploading...</span>}
            </div>

            <div className="mb-4">
              <div className="mb-1 flex items-center justify-between">
                <span className="text-sm font-medium text-gray-700">Sizes</span>
                <button onClick={addSize} className="text-xs text-blue-600 hover:underline">+ Add size</button>
              </div>
              {form.sizes.map((s, idx) => (
                <div key={idx} className="mb-2 flex gap-2">
                  <input
                    placeholder="Label"
                    className="w-1/2 rounded-md border border-gray-300 px-2 py-1 text-sm"
                    value={s.label}
                    onChange={(e) => updateSize(idx, "label", e.target.value)}
                  />
                  <input
                    placeholder="Price"
                    type="number"
                    className="w-1/3 rounded-md border border-gray-300 px-2 py-1 text-sm"
                    value={s.price}
                    onChange={(e) => updateSize(idx, "price", e.target.value)}
                  />
                  <button onClick={() => removeSize(idx)} className="text-gray-400 hover:text-red-600">
                    <Trash2 size={14} />
                  </button>
                </div>
              ))}
            </div>

            <div className="flex justify-end gap-2">
              <button
                onClick={() => setForm(null)}
                className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={submitForm}
                disabled={createMutation.isPending || updateMutation.isPending}
                className="rounded-md bg-gray-900 px-3 py-2 text-sm text-white hover:bg-gray-800 disabled:opacity-50"
              >
                {form.id ? "Save Changes" : "Create Product"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
