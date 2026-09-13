import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { ContactMessage } from "../../lib/types";
import { Badge, Button, Card, EmptyState, PageHeader, Spinner, Table, Td, Th } from "../../components/ui";
import { MailOpen } from "lucide-react";

export default function Inbox() {
  const qc = useQueryClient();
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [openId, setOpenId] = useState<string | null>(null);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["inbox", unreadOnly],
    queryFn: async () =>
      (
        await api.get<ContactMessage[]>("/admin/contact-messages", {
          params: unreadOnly ? { unread_only: true } : {},
        })
      ).data,
    refetchInterval: 60_000,
  });

  const readMut = useMutation({
    mutationFn: (id: string) => api.patch(`/admin/contact-messages/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["inbox"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
    },
  });

  const open = data?.find((m) => m.id === openId) ?? null;

  return (
    <div>
      <PageHeader
        title="Support inbox"
        subtitle="Website contact-form messages — wired to /admin/contact-messages"
        action={
          <Button
            variant="secondary"
            onClick={() => setUnreadOnly((v) => !v)}
          >
            {unreadOnly ? "Show all" : "Unread only"}
          </Button>
        }
      />
      {isLoading ? (
        <Spinner />
      ) : !data || data.length === 0 ? (
        <Card>
          <EmptyState message={unreadOnly ? "Inbox zero — nothing unread." : "No messages yet."} />
        </Card>
      ) : (
        <div className="grid grid-cols-5 gap-4">
          <div className="col-span-2">
            <Table>
              <thead>
                <tr>
                  <Th>Subject</Th>
                  <Th>From</Th>
                  <Th>Received</Th>
                </tr>
              </thead>
              <tbody>
                {data.map((m) => (
                  <tr
                    key={m.id}
                    onClick={() => {
                      setOpenId(m.id);
                      if (!m.is_read) readMut.mutate(m.id);
                    }}
                    className={`cursor-pointer ${openId === m.id ? "bg-surface-2" : ""} ${m.is_read ? "" : "font-semibold"}`}
                  >
                    <Td>
                      <span className="mr-2 inline-block h-2 w-2 rounded-full" style={{ background: m.is_read ? "transparent" : "#eab308" }} />
                      {m.subject}
                    </Td>
                    <Td>{m.name}</Td>
                    <Td>{new Date(m.created_at).toLocaleString()}</Td>
                  </tr>
                ))}
              </tbody>
            </Table>
          </div>
          <div className="col-span-3">
            <Card>
              {!open ? (
                <EmptyState message="Select a message to read it." />
              ) : (
                <div>
                  <div className="mb-1 flex items-center justify-between">
                    <h2 className="text-base font-semibold text-white">{open.subject}</h2>
                    <Badge tone={open.is_read ? "neutral" : "warning"}>
                      {open.is_read ? "Read" : "Unread"}
                    </Badge>
                  </div>
                  <p className="mb-4 text-xs text-neutral-500">
                    From {open.name} ({open.email}) · {new Date(open.created_at).toLocaleString()}
                  </p>
                  <p className="whitespace-pre-wrap text-sm text-neutral-200">{open.message}</p>
                  <div className="mt-4 flex gap-2">
                    <a
                      href={`mailto:${open.email}?subject=${encodeURIComponent(`Re: ${open.subject}`)}`}
                      className="inline-flex items-center gap-2 rounded-lg bg-surface-2 border border-border px-3.5 py-2 text-sm font-medium text-white hover:bg-neutral-800"
                    >
                      <MailOpen size={15} /> Reply by email
                    </a>
                    {!open.is_read && (
                      <Button variant="secondary" onClick={() => readMut.mutate(open.id)}>
                        Mark as read
                      </Button>
                    )}
                    <Button variant="ghost" onClick={() => { setOpenId(null); refetch(); }}>
                      Refresh
                    </Button>
                  </div>
                </div>
              )}
            </Card>
          </div>
        </div>
      )}
    </div>
  );
}
