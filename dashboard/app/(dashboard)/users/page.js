"use client";

import Link from "next/link";
import { usePaginatedList } from "@/lib/usePaginatedList";
import RecordsTable from "@/components/RecordsTable";
import { ErrorState } from "@/components/StateViews";

export default function UsersPage() {
  const { params, data, loading, error, update } =
    usePaginatedList("/admin/users/list", {
      search: "",
      role: "",
      is_active: "",
    });

  return (
    <div>
      <div className="card-header">
        <h2>Users</h2>
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
            placeholder="Name or email"
            value={params.search}
            onChange={(event) =>
              update({ search: event.target.value })
            }
          />
        </div>
        <div className="form-group">
          <label className="form-label" htmlFor="role">
            Role
          </label>
          <select
            id="role"
            className="form-select"
            value={params.role}
            onChange={(event) =>
              update({ role: event.target.value })
            }
          >
            <option value="">All roles</option>
            <option value="CUSTOMER">Customer</option>
            <option value="SERVICE_PROVIDER">
              Service provider
            </option>
            <option value="ADMIN">Admin</option>
          </select>
        </div>
        <div className="form-group">
          <label className="form-label" htmlFor="is_active">
            Status
          </label>
          <select
            id="is_active"
            className="form-select"
            value={params.is_active}
            onChange={(event) =>
              update({ is_active: event.target.value })
            }
          >
            <option value="">All</option>
            <option value="true">Active</option>
            <option value="false">Inactive</option>
          </select>
        </div>
      </div>
      {error && (
        <ErrorState message={error} onRetry={undefined} />
      )}
      <RecordsTable
        loading={loading}
        items={data?.items || []}
        page={data?.page || params.page}
        totalPages={data?.total_pages || 0}
        total={data?.total || 0}
        onPageChange={(page) => update({ page })}
        emptyMessage="No users match your filters."
        columns={[
          {
            key: "name",
            label: "Name",
            render: (user) => (
              <Link href={`/users/${user.id}`}>
                {user.first_name} {user.last_name}
              </Link>
            ),
          },
          { key: "email", label: "Email" },
          {
            key: "role",
            label: "Role",
            render: (user) => (
              <span className="badge badge-neutral">
                {user.role}
              </span>
            ),
          },
          {
            key: "is_active",
            label: "Status",
            render: (user) =>
              user.is_active ? (
                <span className="badge badge-success">
                  Active
                </span>
              ) : (
                <span className="badge badge-error">
                  Inactive
                </span>
              ),
          },
        ]}
      />
    </div>
  );
}
