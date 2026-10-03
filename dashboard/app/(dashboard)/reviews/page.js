"use client";

import { usePaginatedList } from "@/lib/usePaginatedList";
import RecordsTable from "@/components/RecordsTable";
import { ErrorState } from "@/components/StateViews";

export default function ReviewsPage() {
  const { params, data, loading, error, update } =
    usePaginatedList("/admin/reviews", {});

  return (
    <div>
      <div className="card-header">
        <h2>Reviews</h2>
      </div>
      {error && <ErrorState message={error} onRetry={undefined} />}
      <RecordsTable
        loading={loading}
        items={data?.items || []}
        page={data?.page || params.page}
        totalPages={data?.total_pages || 0}
        total={data?.total || 0}
        onPageChange={(page) => update({ page })}
        emptyMessage="No reviews yet."
        columns={[
          {
            key: "id",
            label: "Review",
            render: (review) => (
              <span>{review.id.slice(0, 8)}...</span>
            ),
          },
          {
            key: "customer_id",
            label: "Customer",
            render: (review) => (
              <span>{review.customer_id.slice(0, 8)}...</span>
            ),
          },
          {
            key: "provider_id",
            label: "Provider",
            render: (review) => (
              <span>{review.provider_id.slice(0, 8)}...</span>
            ),
          },
          {
            key: "rating",
            label: "Rating",
            render: (review) => `${review.rating} / 5`,
          },
          {
            key: "comment",
            label: "Comment",
            render: (review) => review.comment || "—",
          },
          {
            key: "created_at",
            label: "Created",
            render: (review) =>
              new Date(review.created_at).toLocaleDateString(),
          },
        ]}
      />
    </div>
  );
}
