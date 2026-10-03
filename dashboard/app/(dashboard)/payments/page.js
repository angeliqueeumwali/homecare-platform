"use client";

import { usePaginatedList } from "@/lib/usePaginatedList";
import RecordsTable from "@/components/RecordsTable";
import { StatusCell } from "@/components/RecordsTable";
import { ErrorState } from "@/components/StateViews";

export default function PaymentsPage() {
  const { params, data, loading, error, update } =
    usePaginatedList("/admin/payments", {
      status: "",
      method: "",
    });

  return (
    <div>
      <div className="card-header">
        <h2>Payments</h2>
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
            <option value="PENDING">Pending</option>
            <option value="PROCESSING">Processing</option>
            <option value="PAID">Paid</option>
            <option value="FAILED">Failed</option>
            <option value="REFUNDED">Refunded</option>
          </select>
        </div>
        <div className="form-group">
          <label className="form-label" htmlFor="method">
            Method
          </label>
          <select
            id="method"
            className="form-select"
            value={params.method}
            onChange={(event) =>
              update({ method: event.target.value })
            }
          >
            <option value="">All methods</option>
            <option value="MOBILE_MONEY">Mobile money</option>
            <option value="CARD">Card</option>
            <option value="CASH">Cash</option>
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
        emptyMessage="No payments match your filters."
        columns={[
          {
            key: "id",
            label: "Payment",
            render: (payment) => (
              <span>{payment.id.slice(0, 8)}...</span>
            ),
          },
          {
            key: "service_request_id",
            label: "Request",
            render: (payment) => (
              <span>
                {payment.service_request_id.slice(0, 8)}...
              </span>
            ),
          },
          {
            key: "amount",
            label: "Amount",
            render: (payment) =>
              `${payment.amount} ${payment.currency}`,
          },
          {
            key: "payment_method",
            label: "Method",
            render: (payment) => (
              <span className="badge badge-neutral">
                {payment.payment_method.replace("_", " ")}
              </span>
            ),
          },
          {
            key: "status",
            label: "Status",
            render: (payment) => (
              <StatusCell value={payment.status} />
            ),
          },
          {
            key: "transaction_reference",
            label: "Reference",
            render: (payment) =>
              payment.transaction_reference || "—",
          },
        ]}
      />
    </div>
  );
}
