export default function StatusBadge({ value }) {
  if (!value) return null;
  const raw = String(value).toUpperCase();
  const map = {
    PENDING: "badge-warning",
    IN_PROGRESS: "badge-info",
    COMPLETED: "badge-success",
    CANCELLED: "badge-error",
    APPROVED: "badge-success",
    REJECTED: "badge-error",
    PAID: "badge-success",
    FAILED: "badge-error",
    REFUNDED: "badge-info",
    PROCESSING: "badge-info",
    OPEN: "badge-error",
    UNDER_REVIEW: "badge-warning",
    RESOLVED: "badge-success",
    PENDING_APPROVAL: "badge-warning",
  };
  const cls = map[raw] || "badge-neutral";
  return <span className={`badge ${cls}`}>{value}</span>;
}
