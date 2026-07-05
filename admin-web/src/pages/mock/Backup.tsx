import { useState } from "react";
import { Badge, Button, Card, MockBanner, PageHeader } from "../../components/ui";

export default function Backup() {
  const [log, setLog] = useState<string[]>([]);

  return (
    <div>
      <PageHeader title="Backup" subtitle="DB backup/restore — infra operation, handled via pg_dump/hosting tooling, not an in-app action" />
      <MockBanner note="Clicking these only appends to the local log below; nothing is actually backed up." />
      <Card className="mb-4 flex gap-3">
        <Button onClick={() => setLog((l) => [`Backup triggered at ${new Date().toLocaleTimeString()}`, ...l])}>
          Trigger backup now
        </Button>
        <Button variant="secondary" onClick={() => setLog((l) => [`Restore requested at ${new Date().toLocaleTimeString()}`, ...l])}>
          Restore from latest
        </Button>
      </Card>
      <Card>
        <div className="mb-3 text-sm font-medium text-white">Recent activity</div>
        <div className="space-y-2">
          {log.length === 0 && <div className="text-sm text-neutral-500">No activity yet</div>}
          {log.map((l, i) => (
            <div key={i} className="flex items-center justify-between text-sm">
              <span className="text-neutral-300">{l}</span>
              <Badge tone="success">done</Badge>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}
