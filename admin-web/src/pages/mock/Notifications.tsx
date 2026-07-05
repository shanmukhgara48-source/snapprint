import SimpleMockList, { Badge } from "./SimpleMockList";

interface Notif {
  id: string;
  title: string;
  audience: string;
  status: string;
}

const initial: Notif[] = [
  { id: "1", title: "Your order has shipped!", audience: "customer", status: "sent" },
  { id: "2", title: "New delivery assignment", audience: "delivery", status: "sent" },
];

export default function Notifications() {
  return (
    <SimpleMockList<Notif>
      title="Notifications"
      subtitle="FCM push exists in the app (order placed/status), but there's no admin compose/broadcast UI or log — this is illustrative"
      columns={[
        { key: "title", label: "Title" },
        { key: "audience", label: "Audience" },
        { key: "status", label: "Status", render: (r) => <Badge tone="success">{r.status}</Badge> },
      ]}
      initialRows={initial}
      addFields={[
        { key: "title", label: "Title" },
        { key: "audience", label: "Audience (customer/delivery/all)" },
      ]}
      onAdd={(v) => ({ id: crypto.randomUUID(), title: v.title, audience: v.audience, status: "sent" })}
    />
  );
}
