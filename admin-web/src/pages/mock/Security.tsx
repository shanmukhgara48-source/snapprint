import { useState } from "react";
import { Card, MockBanner, PageHeader } from "../../components/ui";

const toggles = [
  { key: "2fa", label: "Require 2FA for admin login", desc: "Not implemented — flagged as a future hardening item" },
  { key: "ip_allowlist", label: "Restrict admin login to IP allowlist", desc: "No allowlist model exists" },
  { key: "session_timeout", label: "Auto-expire sessions after 30 min idle", desc: "JWT expiry is currently fixed at 8h" },
];

export default function Security() {
  const [state, setState] = useState<Record<string, boolean>>({});
  return (
    <div>
      <PageHeader title="Security" subtitle="Hardening toggles — none of these are wired to real enforcement yet" />
      <MockBanner />
      <div className="space-y-3">
        {toggles.map((t) => (
          <Card key={t.key} className="flex items-center justify-between">
            <div>
              <div className="text-sm text-white">{t.label}</div>
              <div className="text-xs text-neutral-500">{t.desc}</div>
            </div>
            <button
              onClick={() => setState((s) => ({ ...s, [t.key]: !s[t.key] }))}
              className={`h-6 w-11 rounded-full transition-colors ${state[t.key] ? "bg-accent" : "bg-neutral-700"}`}
            >
              <div
                className={`h-5 w-5 rounded-full bg-white transition-transform ${state[t.key] ? "translate-x-5" : "translate-x-0.5"}`}
              />
            </button>
          </Card>
        ))}
      </div>
    </div>
  );
}
