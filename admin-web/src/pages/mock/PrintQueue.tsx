import SimpleMockList, { Badge } from "./SimpleMockList";

interface Job {
  id: string;
  order_ref: string;
  item: string;
  status: string;
  printer: string;
}

const initial: Job[] = [
  { id: "1", order_ref: "#a1b2c3d4", item: "4x6 Glossy Print x12", status: "queued", printer: "Printer-1" },
  { id: "2", order_ref: "#e5f6a7b8", item: "8x10 Matte Print x2", status: "printing", printer: "Printer-2" },
  { id: "3", order_ref: "#c9d0e1f2", item: "Photo Book (20pg)", status: "done", printer: "Printer-1" },
];

export default function PrintQueue() {
  return (
    <SimpleMockList<Job>
      title="Print Queue"
      subtitle="Print job scheduling — no physical-printer model exists in the backend yet"
      columns={[
        { key: "order_ref", label: "Order" },
        { key: "item", label: "Item" },
        { key: "printer", label: "Printer" },
        { key: "status", label: "Status", render: (r) => <Badge tone={r.status === "done" ? "success" : "warning"}>{r.status}</Badge> },
      ]}
      initialRows={initial}
    />
  );
}
