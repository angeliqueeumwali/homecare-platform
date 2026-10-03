"use client";

import Link from "next/link";
import { usePaginatedList } from "@/lib/usePaginatedList";
import RecordsTable from "@/components/RecordsTable";
import { StatusCell } from "@/components/RecordsTable";
import { ErrorState } from "@/components/StateViews";

export default function ProvidersPage() {
  const { params, data, loading, error, update } =
    usePaginatedList("/admin/providers/list", {
      search: "",
      approval_status: "",
    });

  return (
    <div>
      <div className="card-header">
        <h2>Providers</h2>
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
            placeholder="Business name"
            value={params.search}
            onChange={(event) =>
              update({ search: event.target.value })
            }
          />
        </div>
        <div className="form-group">
          <label className="form-label" htmlFor="approval_status">
            Approval status
          </label>
          <select
            id="approval_status"
            className="form-select"
            value={params.approval_status}
            onChange={(event) =>
              update({ approval_status: event.target.value })
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
        emptyMessage="No providers match your filters."
        columns={[
          {
            key: "business_name",
            label: "Business",
            render: (provider) => (
              <Link href={`/providers/${provider.id}`}>
                {provider.business_name || "—"}
              </Link>
            ),
          },
          {
            key: "approval_status",
            label: "Approval",
            render: (provider) => (
              <StatusCell value={provider.approval_status} />
            ),
          },
          {
            key: "is_available",
            label: "Availability",
            render: (provider) =>
              provider.is_available ? (
                <span className="badge badge-success">
                  Available
                </span>
              ) : (
                <span className="badge badge-neutral">
                  Unavailable
                </span>
              ),
          },
          {
            key: "average_rating",
            label: "Rating",
            render: (provider) =>
              provider.average_rating != null
                ? Number(provider.average_rating).toFixed(1)
                : "—",
          },
        ]}
      />
    </div>
  );
}
