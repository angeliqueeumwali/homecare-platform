"use client";

import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { api } from "@/lib/api";
import { LoadingState, ErrorState } from "@/components/StateViews";
import ConfirmDialog from "@/components/ConfirmDialog";

export default function UserDetailPage() {
  const { id } = useParams();
  const router = useRouter();
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [actionError, setActionError] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const data = await api.get(`/admin/users/${id}`);
      setUser(data);
    } catch (err) {
      setError(err.message || "Failed to load user.");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  async function handleToggleStatus() {
    setSaving(true);
    setActionError("");
    try {
      const updated = await api.patch(
        `/admin/users/${id}/status?is_active=${!user.is_active}`
      );
      setUser(updated);
    } catch (err) {
      setActionError(err.message || "Failed to update user.");
    } finally {
      setSaving(false);
      setConfirmOpen(false);
    }
  }

  if (loading) return <LoadingState label="Loading user..." />;
  if (error) return <ErrorState message={error} onRetry={load} />;

  return (
    <div>
      <div className="card-header">
        <h2>
          {user.first_name} {user.last_name}
        </h2>
        <div style={{ display: "flex", gap: "0.75rem" }}>
          <Link className="btn btn-outline" href="/users">
            Back to users
          </Link>
          <button
            type="button"
            className={`btn ${
              user.is_active ? "btn-danger" : "btn-primary"
            }`}
            onClick={() => setConfirmOpen(true)}
          >
            {user.is_active ? "Deactivate user" : "Activate user"}
          </button>
        </div>
      </div>
      {actionError && (
        <div className="alert alert-error" role="alert">
          {actionError}
        </div>
      )}
      <div className="card">
        <dl className="detail-grid">
          <div className="detail-item">
            <dt>User ID</dt>
            <dd>{user.id}</dd>
          </div>
          <div className="detail-item">
            <dt>Email</dt>
            <dd>{user.email}</dd>
          </div>
          <div className="detail-item">
            <dt>Phone</dt>
            <dd>{user.phone_number}</dd>
          </div>
          <div className="detail-item">
            <dt>Role</dt>
            <dd>
              <span className="badge badge-neutral">
                {user.role}
              </span>
            </dd>
          </div>
          <div className="detail-item">
            <dt>Status</dt>
            <dd>
              {user.is_active ? (
                <span className="badge badge-success">Active</span>
              ) : (
                <span className="badge badge-error">
                  Inactive
                </span>
              )}
            </dd>
          </div>
        </dl>
      </div>
      <ConfirmDialog
        open={confirmOpen}
        title={
          user.is_active ? "Deactivate user" : "Activate user"
        }
        message={
          user.is_active
            ? `Are you sure you want to deactivate ${user.first_name} ${user.last_name}? They will no longer be able to sign in.`
            : `Are you sure you want to activate ${user.first_name} ${user.last_name}? They will be able to sign in again.`
        }
        confirmLabel={
          user.is_active ? "Deactivate" : "Activate"
        }
        destructive={user.is_active}
        onConfirm={handleToggleStatus}
        onCancel={() => setConfirmOpen(false)}
      />
      {saving && (
        <div className="page-state" role="status">
          <div className="spinner" aria-hidden="true" />
        </div>
      )}
    </div>
  );
}
