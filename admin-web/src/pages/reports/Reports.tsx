import { useState } from "react";
import { api } from "../../lib/api";
import { Button, Card, Input, PageHeader } from "../../components/ui";
import { FileDown } from "lucide-react";

async function download(url: string, params: Record<string, string | undefined>, filename: string) {
  const res = await api.get(url, {
    params: Object.fromEntries(Object.entries(params).filter(([, v]) => v)),
    responseType: "blob",
  });
  const objUrl = URL.createObjectURL(res.data as Blob);
  const a = document.createElement("a");
  a.href = objUrl;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(objUrl);
}

export default function Reports() {
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [busy, setBusy] = useState<string | null>(null);

  async function run(key: string, fn: () => Promise<void>) {
    setBusy(key);
    try {
      await fn();
    } finally {
      setBusy(null);
    }
  }

  const range = { created_from: from || undefined, created_to: to || undefined };

  return (
    <div>
      <PageHeader
        title="Reports"
        subtitle="Exportable business reports — every button downloads a live CSV from the backend"
      />
      <Card className="mb-4 flex flex-wrap items-end gap-3 p-4">
        <div>
          <div className="mb-1 text-xs text-neutral-500">From (YYYY-MM-DD)</div>
          <Input type="date" value={from} onChange={(e) => setFrom(e.target.value)} className="w-44" />
        </div>
        <div>
          <div className="mb-1 text-xs text-neutral-500">To (YYYY-MM-DD)</div>
          <Input type="date" value={to} onChange={(e) => setTo(e.target.value)} className="w-44" />
        </div>
        <div className="pb-0.5 text-xs text-neutral-500">Date range applies to sales + orders reports.</div>
      </Card>

      <div className="grid grid-cols-3 gap-4">
        <Card>
          <div className="mb-1 text-sm font-medium text-white">Sales by product</div>
          <div className="mb-4 text-xs text-neutral-500">Units + revenue per product (excludes cancelled orders).</div>
          <Button
            variant="secondary"
            className="w-full justify-center"
            disabled={busy !== null}
            onClick={() => run("sales", () => download("/admin/reports/sales-by-product", range, "snapprint-sales-by-product.csv"))}
          >
            <FileDown size={15} /> {busy === "sales" ? "Preparing…" : "Export CSV"}
          </Button>
        </Card>
        <Card>
          <div className="mb-1 text-sm font-medium text-white">Inventory valuation</div>
          <div className="mb-4 text-xs text-neutral-500">Every product with live stock + all-time sell-through.</div>
          <Button
            variant="secondary"
            className="w-full justify-center"
            disabled={busy !== null}
            onClick={() => run("inv", () => download("/admin/products/export", {}, "snapprint-inventory.csv"))}
          >
            <FileDown size={15} /> {busy === "inv" ? "Preparing…" : "Export CSV"}
          </Button>
        </Card>
        <Card>
          <div className="mb-1 text-sm font-medium text-white">Order fulfilment</div>
          <div className="mb-4 text-xs text-neutral-500">Full order list for the selected range (all statuses).</div>
          <Button
            variant="secondary"
            className="w-full justify-center"
            disabled={busy !== null}
            onClick={() => run("orders", () => download("/admin/orders/export", range, "snapprint-orders.csv"))}
          >
            <FileDown size={15} /> {busy === "orders" ? "Preparing…" : "Export CSV"}
          </Button>
        </Card>
      </div>
    </div>
  );
}
