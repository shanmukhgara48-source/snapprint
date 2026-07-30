import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { DeliverySetting } from "../../lib/types";
import { Badge, Button, Card, ErrorState, Input, PageHeader, Spinner } from "../../components/ui";
import { useState } from "react";

export default function DeliverySettings() {
  const qc = useQueryClient();
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["delivery-settings"],
    queryFn: async () => (await api.get<DeliverySetting[]>("/admin/delivery-settings")).data,
  });

  const updateMut = useMutation({
    mutationFn: ({ type, payload }: { type: string; payload: Partial<DeliverySetting> }) =>
      api.put(`/admin/delivery-settings/${type}`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["delivery-settings"] }),
  });

  if (isLoading) return <Spinner />;
  if (isError || !data) return <ErrorState message="Failed to load delivery settings." onRetry={() => refetch()} />;

  return (
    <div>
      <PageHeader title="Delivery Settings" subtitle="Full CRUD wired to /admin/delivery-settings" />
      <div className="grid grid-cols-3 gap-4">
        {data.map((s) => (
          <SettingCard key={s.type} setting={s} onSave={(payload) => updateMut.mutate({ type: s.type, payload })} />
        ))}
      </div>
    </div>
  );
}

function SettingCard({
  setting,
  onSave,
}: {
  setting: DeliverySetting;
  onSave: (payload: Partial<DeliverySetting>) => void;
}) {
  const [label, setLabel] = useState(setting.label);
  const [price, setPrice] = useState(String(setting.price));
  const [daysLabel, setDaysLabel] = useState(setting.days_label);

  return (
    <Card>
      <div className="mb-3 flex items-center justify-between">
        <span className="text-xs uppercase tracking-wide text-neutral-500">{setting.type}</span>
        <Badge tone={setting.is_active ? "success" : "neutral"}>{setting.is_active ? "Active" : "Disabled"}</Badge>
      </div>
      <label className="mb-1 block text-xs text-neutral-500">Label</label>
      <Input value={label} onChange={(e) => setLabel(e.target.value)} className="mb-3" />
      <label className="mb-1 block text-xs text-neutral-500">Price (₹)</label>
      <Input value={price} onChange={(e) => setPrice(e.target.value)} type="number" className="mb-3" />
      <label className="mb-1 block text-xs text-neutral-500">Days label</label>
      <Input value={daysLabel} onChange={(e) => setDaysLabel(e.target.value)} className="mb-4" />
      <div className="flex gap-2">
        <Button
          variant="secondary"
          className="flex-1 justify-center"
          onClick={() => onSave({ label, price: Number(price), days_label: daysLabel })}
        >
          Save
        </Button>
        <Button variant="secondary" onClick={() => onSave({ is_active: !setting.is_active })}>
          {setting.is_active ? "Disable" : "Enable"}
        </Button>
      </div>
    </Card>
  );
}
