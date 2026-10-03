"use client";

import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { api } from "@/lib/api";
import { LoadingState, ErrorState } from "@/components/StateViews";
import { StatusBadge } from "@/components/StatusBadge";
import ConfirmDialog from "@/components/ConfirmDialog";

export default function ProviderDetailPage() {
  const { id } = useParams();
  const router = useRouter();
  const [details, setDetails] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [dialog, setDialog] = useState(null);
  const [actionError, setActionError] = useState("");
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const data = await api.get(`/admin/providers/${id}`);
      setDetails(data);
    } catch (err) {
      setError(err.message || "Failed to load provider.");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  async function handleApproval(approved) {
    setSaving(true);
    setActionError("");
    try {
      const updated = await api.patch(
        `/admin/providers/${id}/approval`,
        { approved }
      );
      setDetails((current) => ({
        ...current,
        provider: updated,
      }));
    } catch (err) {
      setActionError(
        err.message || "Failed to update approval status."
      );
    } finally {
      setSaving(false);
      setDialog(null);
    }
  }

  if (loading) return <LoadingState label="Loading provider..." />;
  if (error) return <ErrorState message={error} onRetry={load} />;

  const provider = details.provider;
  const pending = provider.approval_status === "PENDING";

  return (
    <div>
      <div className="card-header">
        <h2>{provider.business_name || "Provider"}</h2>
        <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap" }}>
          <Link className="btn btn-outline" href="/providers">
            Back to providers
          </Link>
          {pending && (
            <>
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => setDialog("approve")}
              >
                Approve
              </button>
              <button
                type="button"
                className="btn btn-danger"
                onClick={() => setDialog("reject")}
              >
                Reject
              </button>
            </>
          )}
        </div>
      </div>
      {actionError && (
        <div className="alert alert-error" role="alert">
          {actionError}
        </div>
      )}
      <div className="card">
        <div className="card-header">
          <h3>Profile</h3>
          <StatusBadge value={provider.approval_status} />
        </div>
        <dl className="detail-grid">
          <div className="detail-item">
            <dt>Provider ID</dt>
            <dd>{provider.id}</dd>
          </div>
          <div className="detail-item">
            <dt>User ID</dt>
            <dd>{provider.user_id}</dd>
          </div>
          <div className="detail-item">
            <dt>Business name</dt>
            <dd>{provider.business_name || "—"}</dd>
          </div>
          <div className="detail-item">
            <dt>Bio</dt>
            <dd>{provider.bio || "—"}</dd>
          </div>
          <div className="detail-item">
            <dt>Average rating</dt>
            <dd>
              {provider.average_rating != null
                ? Number(provider.average_rating).toFixed(1)
                : "No ratings yet"}
            </dd>
          </div>
          <div className="detail-item">
            <dt>Availability</dt>
            <dd>
              {provider.is_available ? "Available" : "Unavailable"}
            </dd>
          </div>
        </dl>
      </div>
      <div className="card">
        <h3 className="section-title" style={{ marginTop: 0 }}>
          Service categories
        </h3>
        {details.service_category_ids.length > 0 ? (
          <ul>
            {details.service_category_ids.map((categoryId) => (
              <li key={categoryId}>{categoryId}</li>
            ))}
          </ul>
        ) : (
          <p className="state-text">No service categories linked.</p>
        )}
      </div>
      <div className="card">
        <h3 className="section-title" style={{ marginTop: 0 }}>
          Activity
        </h3>
        <dl className="detail-grid">
          <div className="detail-item">
            <dt>Assignments</dt>
            <dd>{details.assignment_ids.length}</dd>
          </div>
          <div className="detail-item">
            <dt>Reviews</dt>
            <dd>{details.review_ids.length}</dd>
          </div>
        </dl>
        {details.location ? (
          <div className="card" style={{ marginTop: "1rem" }}>
            <h3 className="section-title" style={{ marginTop: 0 }}>
              Location
            </h3>
            <dl className="detail-grid">
              <div className="detail-item">
                <dt>Coordinates</dt>
                <dd>
                  {details.location.latitude},{" "}
                  {details.location.longitude}
                </dd>
              </div>
              <div className="detail-item">
                <dt>Address</dt>
                <dd>{details.location.address || "—"}</dd>
              </div>
            </dl>
          </div>
        ) : (
          <p className="state-text">No location set.</p>
        )}
      </div>
      <ConfirmDialog
        open={dialog === "approve"}
        title="Approve provider"
        message={`Are you sure you want to approve ${provider.business_name}? They will be able to receive assignments.`}
        confirmLabel="Approve"
        onConfirm={() => handleApproval(true)}
        onCancel={() => setDialog(null)}
      />
      <ConfirmDialog
        open={dialog === "reject"}
        title="Reject provider"
        message={`Are you sure you want to reject ${provider.business_name}? This can be changed later by approving them again.`}
        confirmLabel="Reject"
        destructive
        onConfirm={() => handleApproval(false)}
        onCancel={() => setDialog(null)}
      />
      {saving && (
        <div className="page-state" role="status">
          <div className="spinner" aria-hidden="true" />
        </div>
      )}
    </div>
  );
}
