import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "../lib/api";
import { Badge, Input, Button, PageHeader, Spinner, Table, Td, Th, MockBanner } from "../components/ui";
import { Plus, Trash2 } from "lucide-react";

export default function Categories() {
  const { data, isLoading } = useQuery({
    queryKey: ["categories"],
    queryFn: async () => (await api.get<string[]>("/admin/categories")).data,
  });
  const [extra, setExtra] = useState<string[]>([]);
  const [newCat, setNewCat] = useState("");

  if (isLoading) return <Spinner />;

  const rows = [...(data ?? []), ...extra];

  return (
    <div>
      <PageHeader
        title="Categories"
        subtitle="The list below (in bold) is real — derived from existing products via /admin/categories. There's no dedicated category table, so add/remove here is local-only."
        action={
          <div className="flex gap-2">
            <Input placeholder="New category" value={newCat} onChange={(e) => setNewCat(e.target.value)} className="w-48" />
            <Button
              onClick={() => {
                if (newCat.trim()) {
                  setExtra((e) => [...e, newCat.trim()]);
                  setNewCat("");
                }
              }}
            >
              <Plus size={16} /> Add
            </Button>
          </div>
        }
      />
      <MockBanner note="Add/remove only affects this screen — creating a real category means creating a Product in that category." />
      <Table>
        <thead>
          <tr>
            <Th>Category</Th>
            <Th>Source</Th>
            <Th>Actions</Th>
          </tr>
        </thead>
        <tbody>
          {rows.map((c) => (
            <tr key={c}>
              <Td className="capitalize">{c}</Td>
              <Td>
                <Badge tone={data?.includes(c) ? "success" : "neutral"}>{data?.includes(c) ? "From products" : "Local only"}</Badge>
              </Td>
              <Td>
                {!data?.includes(c) && (
                  <button onClick={() => setExtra((e) => e.filter((x) => x !== c))} className="text-red-500 hover:text-red-400">
                    <Trash2 size={15} />
                  </button>
                )}
              </Td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
