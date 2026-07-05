import { Card, MockBanner, PageHeader } from "../../components/ui";
import { ImageOff } from "lucide-react";

const placeholders = Array.from({ length: 8 }, (_, i) => i);

export default function PhotoUploads() {
  return (
    <div>
      <PageHeader
        title="Photo Uploads"
        subtitle="Real photo URLs exist per order item (see Order detail → Items) — this gallery view aggregating all uploads has no dedicated backend endpoint yet"
      />
      <MockBanner note="Order detail already shows the real uploaded photo per item." />
      <div className="grid grid-cols-4 gap-4">
        {placeholders.map((i) => (
          <Card key={i} className="flex aspect-square items-center justify-center p-0">
            <ImageOff className="text-neutral-700" size={28} />
          </Card>
        ))}
      </div>
    </div>
  );
}
