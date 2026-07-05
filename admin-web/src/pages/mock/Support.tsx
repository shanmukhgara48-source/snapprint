import SimpleMockList, { Badge } from "./SimpleMockList";

interface Ticket {
  id: string;
  customer: string;
  subject: string;
  status: string;
}

const initial: Ticket[] = [
  { id: "1", customer: "+91 98765 43210", subject: "Order delayed by 3 days", status: "open" },
  { id: "2", customer: "+91 91234 56789", subject: "Wrong print size received", status: "resolved" },
];

export default function Support() {
  return (
    <SimpleMockList<Ticket>
      title="Support"
      subtitle="Live chat / support tickets — no messaging or ticketing system exists in the stack yet"
      columns={[
        { key: "customer", label: "Customer" },
        { key: "subject", label: "Subject" },
        { key: "status", label: "Status", render: (r) => <Badge tone={r.status === "open" ? "warning" : "success"}>{r.status}</Badge> },
      ]}
      initialRows={initial}
    />
  );
}
