import SimpleMockList, { Badge } from "./SimpleMockList";

interface Offer {
  id: string;
  title: string;
  banner: string;
  active: string;
}

const initial: Offer[] = [
  { id: "1", title: "Diwali Special — 20% off photobooks", banner: "diwali_banner.jpg", active: "yes" },
  { id: "2", title: "First order — Free delivery", banner: "welcome_banner.jpg", active: "yes" },
];

export default function Offers() {
  return (
    <SimpleMockList<Offer>
      title="Offers"
      subtitle="Promotional banners/campaigns — distinct from Coupons; no backend model exists yet"
      columns={[
        { key: "title", label: "Title" },
        { key: "banner", label: "Banner asset" },
        { key: "active", label: "Status", render: (r) => <Badge tone={r.active === "yes" ? "success" : "neutral"}>{r.active === "yes" ? "Live" : "Draft"}</Badge> },
      ]}
      initialRows={initial}
      addFields={[
        { key: "title", label: "Title" },
        { key: "banner", label: "Banner filename" },
      ]}
      onAdd={(v) => ({ id: crypto.randomUUID(), title: v.title, banner: v.banner, active: "yes" })}
    />
  );
}
