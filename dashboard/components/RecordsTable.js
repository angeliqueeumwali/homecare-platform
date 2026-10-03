import StatusBadge from "./StatusBadge";
import Pagination from "./Pagination";
import { EmptyState } from "./StateViews";

export default function RecordsTable({
  columns,
  items,
  page,
  totalPages,
  total,
  onPageChange,
  emptyMessage,
  loading,
}) {
  if (loading) {
    return (
      <div className="table-wrap">
        <div className="page-state" role="status">
          <div className="spinner" aria-hidden="true" />
          <p className="state-text">Loading records...</p>
        </div>
      </div>
    );
  }

  if (!items || items.length === 0) {
    return (
      <div className="table-wrap">
        <EmptyState message={emptyMessage} />
      </div>
    );
  }

  return (
    <>
      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              {columns.map((column) => (
                <th key={column.key} scope="col">
                  {column.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {items.map((item, rowIndex) => (
              <tr key={item.id || rowIndex}>
                {columns.map((column) => (
                  <td key={column.key} data-label={column.label}>
                    {column.render
                      ? column.render(item)
                      : item[column.key] ?? ""}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination
        page={page}
        totalPages={totalPages}
        total={total}
        onChange={onPageChange}
      />
    </>
  );
}

export function StatusCell({ value }) {
  return <StatusBadge value={value} />;
}
