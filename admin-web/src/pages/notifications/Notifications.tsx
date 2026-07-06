import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import { Button, Card, Input, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { Send } from "lucide-react";

interface BroadcastRecord {
  id: string;
  admin_user_id: string;
  title: string | null;
  body: string | null;
  created_at: string;
}

export default function Notifications() {
  const qc = useQueryClient();
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [feedback, setFeedback] = useState<string | null>(null);

  const { data: history, isLoading } = useQuery({
    queryKey: ["notifications"],
    queryFn: async () =>
      (await api.get<BroadcastRecord[]>("/admin/notifications/history")).data,
  });

  const sendMut = useMutation({
    mutationFn: () => api.post("/admin/notifications/broadcast", { title, body }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["notifications"] });
      setTitle("");
      setBody("");
      setFeedback("Broadcast sent to all app users.");
    },
    onError: (err: unknown) => {
      const detail =
        (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail;
      setFeedback(detail ?? "Broadcast failed — check backend logs.");
    },
  });

  return (
    <div>
      <PageHeader
        title="Notifications"
        subtitle="Broadcast push announcements to every app user (FCM topic all_users)"
      />

      <Card className="mb-6 space-y-3 p-4">
        <Input
          placeholder="Title (e.g. Weekend Sale — 20% off all prints!)"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />
        <textarea
          placeholder="Message body…"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          rows={3}
          className="w-full rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white placeholder:text-neutral-500"
        />
        <div className="flex items-center gap-3">
          <Button
            onClick={() => {
              setFeedback(null);
              sendMut.mutate();
            }}
            disabled={sendMut.isPending || !title.trim() || !body.trim()}
          >
            <Send size={16} /> {sendMut.isPending ? "Sending…" : "Send to all users"}
          </Button>
          {feedback && <span className="text-sm text-neutral-400">{feedback}</span>}
        </div>
      </Card>

      <h2 className="mb-3 text-sm font-semibold text-neutral-300">Broadcast history</h2>
      {isLoading ? (
        <Spinner />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Title</Th>
              <Th>Body</Th>
              <Th>Sent</Th>
            </tr>
          </thead>
          <tbody>
            {history?.length === 0 && (
              <tr>
                <Td className="text-neutral-500">No broadcasts yet</Td>
                <Td>{""}</Td>
                <Td>{""}</Td>
              </tr>
            )}
            {history?.map((n) => (
              <tr key={n.id}>
                <Td>{n.title ?? "—"}</Td>
                <Td className="max-w-md truncate">{n.body ?? "—"}</Td>
                <Td>{new Date(n.created_at).toLocaleString()}</Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </div>
  );
}
