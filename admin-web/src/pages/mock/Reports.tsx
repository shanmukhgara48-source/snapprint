import { Button, Card, MockBanner, PageHeader } from "../../components/ui";
import { FileDown } from "lucide-react";

const reports = [
  { name: "Monthly revenue report", desc: "Revenue broken down by day for the selected month" },
  { name: "Order fulfillment report", desc: "Orders by status and average delivery time" },
  { name: "Customer growth report", desc: "New sign-ups and retention over time" },
];

export default function Reports() {
  return (
    <div>
      <PageHeader
        title="Reports"
        subtitle="Underlying numbers are real (see Dashboard/Analytics) — scheduled/exportable report generation isn't built yet"
      />
      <MockBanner note="Buttons below are non-functional placeholders." />
      <div className="grid grid-cols-3 gap-4">
        {reports.map((r) => (
          <Card key={r.name}>
            <div className="mb-1 text-sm font-medium text-white">{r.name}</div>
            <div className="mb-4 text-xs text-neutral-500">{r.desc}</div>
            <Button variant="secondary" className="w-full justify-center">
              <FileDown size={15} /> Export CSV
            </Button>
          </Card>
        ))}
      </div>
    </div>
  );
}
