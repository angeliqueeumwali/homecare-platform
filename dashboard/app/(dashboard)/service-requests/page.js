"use client";

import { usePaginatedList } from "@/lib/usePaginatedList";
import RecordsTable from "@/components/RecordsTable";
import { StatusCell } from "@/components/RecordsTable";
import { ErrorState } from "@/components/StateViews";

export default function ServiceRequestsPage() {
  const { params, data, loading, error, update } =
    usePaginatedList("/admin/service-requests", {
      search: "",
      status: "",
    });

  return (
    <div>
      <div className="card-header">
        <h2>Service Requests</h2>
      </div>
      <div className="filter-bar">
        <div className="form-group">
          <label className="form-label" htmlFor="search">
            Search
          </label>
          <input
            id="search"
            className="form-control"
            type="search"
            placeholder="Address or notes"
            value={params.search}
            onChange={(event) =>
              update({ search: event.target.value })
            }
          />
        </div>
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
            <option value="PENDING">Pending</option>
            <option value="IN_PROGRESS">In progress</option>
            <option value="COMPLETED">Completed</option>
            <option value="CANCELLED">Cancelled</option>
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
        emptyMessage="No service requests match your filters."
        columns={[
          {
            key: "id",
            label: "Request",
            render: (request) => (
              <span>{request.id.slice(0, 8)}...</span>
            ),
          },
          {
            key: "customer_id",
            label: "Customer",
            render: (request) => (
              <span>{request.customer_id.slice(0, 8)}...</span>
            ),
          },
          { key: "address", label: "Address" },
          {
            key: "preferred_date",
            label: "Preferred date",
            render: (request) =>
              request.preferred_date
                ? new Date(
                    request.preferred_date
                  ).toLocaleDateString()
                : "—",
          },
          {
            key: "status",
            label: "Status",
            render: (request) => (
              <StatusCell value={request.status} />
            ),
          },
          {
            key: "created_at",
            label: "Created",
            render: (request) =>
              new Date(request.created_at).toLocaleDateString(),
          },
        ]}
      />
    </div>
  );
}
