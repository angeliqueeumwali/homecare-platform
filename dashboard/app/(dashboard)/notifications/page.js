"use client";

import { usePaginatedList } from "@/lib/usePaginatedList";
import RecordsTable from "@/components/RecordsTable";
import { ErrorState } from "@/components/StateViews";

export default function NotificationsPage() {
  const { params, data, loading, error, update } =
    usePaginatedList("/admin/notifications", {});

  return (
    <div>
      <div className="card-header">
        <h2>Notifications</h2>
      </div>
      {error && <ErrorState message={error} onRetry={undefined} />}
      <RecordsTable
        loading={loading}
        items={data?.items || []}
        page={data?.page || params.page}
        totalPages={data?.total_pages || 0}
        total={data?.total || 0}
        onPageChange={(page) => update({ page })}
        emptyMessage="No notifications yet."
        columns={[
          {
            key: "title",
            label: "Title",
            render: (notification) => notification.title,
          },
          {
            key: "message",
            label: "Message",
            render: (notification) => notification.message,
          },
          {
            key: "user_id",
            label: "User",
            render: (notification) => (
              <span>{notification.user_id.slice(0, 8)}...</span>
            ),
          },
          {
            key: "notification_type",
            label: "Type",
            render: (notification) => (
              <span className="badge badge-neutral">
                {notification.notification_type.replace("_", " ")}
              </span>
            ),
          },
          {
            key: "is_read",
            label: "Read",
            render: (notification) =>
              notification.is_read ? "Yes" : "No",
          },
          {
            key: "created_at",
            label: "Created",
            render: (notification) =>
              new Date(notification.created_at).toLocaleDateString(),
          },
        ]}
      />
    </div>
  );
}
