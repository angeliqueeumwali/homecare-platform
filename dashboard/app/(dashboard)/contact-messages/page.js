"use client";

import { usePaginatedList } from "@/lib/usePaginatedList";
import RecordsTable from "@/components/RecordsTable";
import { ErrorState } from "@/components/StateViews";

export default function ContactMessagesPage() {
  const { params, data, loading, error, update } =
    usePaginatedList("/support/contact-messages", {});

  return (
    <div>
      <div className="card-header">
        <h2>Contact Messages</h2>
      </div>
      {error && <ErrorState message={error} onRetry={undefined} />}
      <RecordsTable
        loading={loading}
        items={data?.items || []}
        page={data?.page || params.page}
        totalPages={data?.total_pages || 0}
        total={data?.total || 0}
        onPageChange={(page) => update({ page })}
        emptyMessage="No contact messages yet."
        columns={[
          { key: "name", label: "Name" },
          { key: "email", label: "Email" },
          { key: "subject", label: "Subject" },
          {
            key: "message",
            label: "Message",
            render: (message) => (
              <span
                style={{
                  display: "block",
                  maxWidth: "320px",
                  whiteSpace: "normal",
                }}
              >
                {message.message}
              </span>
            ),
          },
          {
            key: "ip_address",
            label: "IP address",
            render: (message) => message.ip_address || "—",
          },
          {
            key: "created_at",
            label: "Received",
            render: (message) =>
              new Date(message.created_at).toLocaleString(),
          },
        ]}
      />
    </div>
  );
}
