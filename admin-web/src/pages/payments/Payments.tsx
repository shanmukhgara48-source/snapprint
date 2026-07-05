import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { PaymentAttempt } from "../../lib/types";
import { Badge, Card, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";

export default function Payments() {
  const [status, setStatus] = useState("");

  const { data, isLoading } = useQuery({
    queryKey: ["payments", status],
    queryFn: async () => (await api.get<PaymentAttempt[]>("/admin/payments", { params: { status: status || undefined } })).data,
  });

  return (
    <div>
      <PageHeader title="Payments" subtitle="Every Razorpay verify attempt — wired to /admin/payments" />
      <Card className="mb-4 p-3">
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
        >
          <option value="">All statuses</option>
          <option value="success">Success</option>
          <option value="failed">Failed</option>
        </select>
      </Card>

      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Razorpay order</Th>
              <Th>Payment ID</Th>
              <Th>Status</Th>
              <Th>Reason</Th>
              <Th>When</Th>
            </tr>
          </thead>
          <tbody>
            {data?.map((p) => (
              <tr key={p.id}>
                <Td className="font-mono text-xs">{p.razorpay_order_id ?? "—"}</Td>
                <Td className="font-mono text-xs">{p.razorpay_payment_id ?? "—"}</Td>
                <Td>
                  <Badge tone={p.status === "success" ? "success" : "danger"}>{p.status}</Badge>
                </Td>
                <Td>{p.reason ?? "—"}</Td>
                <Td>{new Date(p.created_at).toLocaleString()}</Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </div>
  );
}
