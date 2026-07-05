import { useState } from "react";
import { Badge, Button, Input, Modal, PageHeader, MockBanner, Table, Td, Th } from "../../components/ui";
import { Plus, Trash2 } from "lucide-react";

export interface MockColumn<T> {
  key: keyof T;
  label: string;
  render?: (row: T) => React.ReactNode;
}

export interface MockField {
  key: string;
  label: string;
  type?: "text" | "number";
}

interface Props<T extends { id: string }> {
  title: string;
  subtitle: string;
  columns: MockColumn<T>[];
  initialRows: T[];
  addFields?: MockField[];
  onAdd?: (values: Record<string, string>) => T;
}

export default function SimpleMockList<T extends { id: string }>({
  title,
  subtitle,
  columns,
  initialRows,
  addFields,
  onAdd,
}: Props<T>) {
  const [rows, setRows] = useState<T[]>(initialRows);
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState<Record<string, string>>({});

  function handleAdd() {
    if (!onAdd) return;
    setRows((prev) => [onAdd(form), ...prev]);
    setModalOpen(false);
    setForm({});
  }

  return (
    <div>
      <PageHeader
        title={title}
        subtitle={subtitle}
        action={
          addFields && (
            <Button onClick={() => setModalOpen(true)}>
              <Plus size={16} /> Add
            </Button>
          )
        }
      />
      <MockBanner />
      <Table>
        <thead>
          <tr>
            {columns.map((c) => (
              <Th key={String(c.key)}>{c.label}</Th>
            ))}
            <Th>Actions</Th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id}>
              {columns.map((c) => (
                <Td key={String(c.key)}>{c.render ? c.render(row) : String(row[c.key] ?? "—")}</Td>
              ))}
              <Td>
                <button
                  onClick={() => setRows((prev) => prev.filter((r) => r.id !== row.id))}
                  className="text-red-500 hover:text-red-400"
                >
                  <Trash2 size={15} />
                </button>
              </Td>
            </tr>
          ))}
        </tbody>
      </Table>

      {addFields && (
        <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={`Add ${title.slice(0, -1)}`}>
          <div className="space-y-3">
            {addFields.map((f) => (
              <Input
                key={f.key}
                placeholder={f.label}
                type={f.type ?? "text"}
                value={form[f.key] ?? ""}
                onChange={(e) => setForm({ ...form, [f.key]: e.target.value })}
              />
            ))}
            <Button onClick={handleAdd} className="w-full justify-center">
              Save
            </Button>
          </div>
        </Modal>
      )}
    </div>
  );
}

export { Badge };
