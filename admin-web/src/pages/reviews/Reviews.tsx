import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { AdminReview } from "../../lib/types";
import { Badge, Button, Card, EmptyState, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { Star } from "lucide-react";

function Stars({ n }: { n: number }) {
  return (
    <span className="inline-flex items-center gap-0.5" aria-label={`${n} out of 5 stars`}>
      {[1, 2, 3, 4, 5].map((i) => (
        <Star
          key={i}
          size={13}
          className={i <= n ? "fill-accent text-accent" : "text-neutral-600"}
        />
      ))}
    </span>
  );
}

export default function Reviews() {
  const qc = useQueryClient();
  const [status, setStatus] = useState("");
  const [respondId, setRespondId] = useState<string | null>(null);
  const [response, setResponse] = useState("");

  const { data, isLoading } = useQuery({
    queryKey: ["reviews", status],
    queryFn: async () =>
      (await api.get<AdminReview[]>("/admin/reviews", { params: status ? { status } : {} })).data,
  });

  const modMut = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: Record<string, unknown> }) =>
      api.patch(`/admin/reviews/${id}`, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["reviews"] });
      setRespondId(null);
      setResponse("");
    },
  });

  return (
    <div>
      <PageHeader
        title="Reviews"
        subtitle="Customer ratings — hide abuse, reply as the seller. Wired to /admin/reviews"
        action={
          <select
            value={status}
            onChange={(e) => setStatus(e.target.value)}
            className="rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white"
          >
            <option value="">All</option>
            <option value="published">Published</option>
            <option value="hidden">Hidden</option>
          </select>
        }
      />
      {isLoading ? (
        <Spinner />
      ) : !data || data.length === 0 ? (
        <Card><EmptyState message="No reviews yet." /></Card>
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Product</Th>
              <Th>Rating</Th>
              <Th>Review</Th>
              <Th>Status</Th>
              <Th>Actions</Th>
            </tr>
          </thead>
          <tbody>
            {data.map((r) => (
              <tr key={r.id}>
                <Td>
                  <div className="text-sm">{r.product_name ?? r.product_id.slice(0, 8)}</div>
                  <div className="text-xs text-neutral-500">
                    {r.reviewer} {r.verified_purchase && "· Verified Purchase"} · {r.helpful_count} helpful
                  </div>
                </Td>
                <Td><Stars n={r.rating} /></Td>
                <Td className="max-w-md">
                  {r.title && <div className="text-sm font-medium text-white">{r.title}</div>}
                  <div className="text-sm text-neutral-300">{r.body || "—"}</div>
                  {r.seller_response ? (
                    <div className="mt-1 rounded bg-surface-2 p-2 text-xs text-neutral-400">
                      <span className="font-semibold text-neutral-300">Seller response: </span>
                      {r.seller_response}
                    </div>
                  ) : (
                    respondId === r.id && (
                      <div className="mt-2 flex gap-2">
                        <input
                          value={response}
                          onChange={(e) => setResponse(e.target.value)}
                          placeholder="Write a public seller response…"
                          maxLength={2000}
                          className="w-full rounded-lg border border-border bg-surface-2 px-3 py-1.5 text-xs text-white outline-none focus:border-accent"
                        />
                        <Button
                          variant="secondary"
                          disabled={!response.trim() || modMut.isPending}
                          onClick={() => modMut.mutate({ id: r.id, payload: { seller_response: response.trim() } })}
                        >
                          Post
                        </Button>
                      </div>
                    )
                  )}
                </Td>
                <Td>
                  <Badge tone={r.status === "published" ? "success" : "neutral"}>{r.status}</Badge>
                </Td>
                <Td>
                  <div className="flex flex-col gap-1 text-xs">
                    {!r.seller_response && respondId !== r.id && (
                      <button onClick={() => { setRespondId(r.id); setResponse(""); }} className="text-left text-neutral-300 hover:text-white">
                        Respond
                      </button>
                    )}
                    <button
                      onClick={() => modMut.mutate({ id: r.id, payload: { status: r.status === "published" ? "hidden" : "published" } })}
                      className="text-left text-neutral-300 hover:text-white"
                    >
                      {r.status === "published" ? "Hide" : "Publish"}
                    </button>
                  </div>
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </div>
  );
}
