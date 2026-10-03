"use client";

import { usePaginatedList } from "@/lib/usePaginatedList";
import RecordsTable from "@/components/RecordsTable";
import { StatusCell } from "@/components/RecordsTable";
import { ErrorState } from "@/components/StateViews";

export default function QuotesPage() {
  const { params, data, loading, error, update } =
    usePaginatedList("/admin/quotes", {
      status: "",
      request_id: "",
    });

  return (
    <div>
      <div className="card-header">
        <h2>Quotes</h2>
      </div>
      <div className="filter-bar">
        <div className="form-group">
          <label className="form-label" htmlFor="request_id">
            Service request ID
          </label>
          <input
            id="request_id"
            className="form-control"
            type="text"
            placeholder="Request UUID"
            value={params.request_id}
            onChange={(event) =>
              update({ request_id: event.target.value })
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
            <option value="APPROVED">Approved</option>
            <option value="REJECTED">Rejected</option>
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
        emptyMessage="No quotes match your filters."
        columns={[
          {
            key: "id",
            label: "Quote",
            render: (quote) => (
              <span>{quote.id.slice(0, 8)}...</span>
            ),
          },
          {
            key: "service_request_id",
            label: "Request",
            render: (quote) => (
              <span>
                {quote.service_request_id.slice(0, 8)}...
              </span>
            ),
          },
          {
            key: "provider_id",
            label: "Provider",
            render: (quote) => (
              <span>{quote.provider_id.slice(0, 8)}...</span>
            ),
          },
          {
            key: "amount",
            label: "Amount",
            render: (quote) =>
              `${quote.amount} ${quote.currency}`,
          },
          {
            key: "status",
            label: "Status",
            render: (quote) => <StatusCell value={quote.status} />,
          },
          {
            key: "created_at",
            label: "Created",
            render: (quote) =>
              new Date(quote.created_at).toLocaleDateString(),
          },
        ]}
      />
    </div>
  );
}
