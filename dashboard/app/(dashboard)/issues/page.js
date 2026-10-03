"use client";

import { usePaginatedList } from "@/lib/usePaginatedList";
import RecordsTable from "@/components/RecordsTable";
import { StatusCell } from "@/components/RecordsTable";
import { ErrorState } from "@/components/StateViews";

export default function IssuesPage() {
  const { params, data, loading, error, update } =
    usePaginatedList("/admin/issues", { status: "" });

  return (
    <div>
      <div className="card-header">
        <h2>Issues</h2>
      </div>
      <div className="filter-bar">
        <div className="form-group">
          <label className="form-label" htmlFor="status">
            Status
          </label>
          <select
            id="status"
            className="form-select"
            value={params.status}
            onChange={(event) =>
              update({ status: event.target.value })
            }
          >
            <option value="">All statuses</option>
            <option value="OPEN">Open</option>
            <option value="UNDER_REVIEW">Under review</option>
            <option value="RESOLVED">Resolved</option>
          </select>
        </div>
      </div>
      {error && <ErrorState message={error} onRetry={undefined} />}
      <RecordsTable
        loading={loading}
        items={data?.items || []}
        page={data?.page || params.page}
        totalPages={data?.total_pages || 0}
        total={data?.total || 0}
        onPageChange={(page) => update({ page })}
        emptyMessage="No issues match your filters."
        columns={[
          {
            key: "id",
            label: "Issue",
            render: (issue) => (
              <span>{issue.id.slice(0, 8)}...</span>
            ),
          },
          {
            key: "title",
            label: "Title",
            render: (issue) => issue.title,
          },
          {
            key: "service_request_id",
            label: "Request",
            render: (issue) => (
              <span>
                {issue.service_request_id.slice(0, 8)}...
              </span>
            ),
          },
          {
            key: "reported_by_id",
            label: "Reported by",
            render: (issue) => (
              <span>{issue.reported_by_id.slice(0, 8)}...</span>
            ),
          },
          {
            key: "status",
            label: "Status",
            render: (issue) => <StatusCell value={issue.status} />,
          },
          {
            key: "resolution",
            label: "Resolution",
            render: (issue) => issue.resolution || "—",
          },
        ]}
      />
    </div>
  );
}
