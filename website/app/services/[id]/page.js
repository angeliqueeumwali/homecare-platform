"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { api } from "@/lib/api";
import { LoadingState, ErrorState } from "@/components/StateViews";

export default function ServiceDetailPage() {
  const { id } = useParams();
  const [category, setCategory] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const data = await api.get(`/service-categories/${id}`);
      setCategory(data);
    } catch (err) {
      setError(
        err.message || "This service could not be found."
      );
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  if (loading) return <LoadingState label="Loading service..." />;
  if (error)
    return (
      <div className="container section">
        <ErrorState message={error} onRetry={load} />
        <div style={{ textAlign: "center", marginTop: "1rem" }}>
          <Link className="btn btn-outline" href="/services">
            Back to services
          </Link>
        </div>
      </div>
    );

  return (
    <div className="container section">
      <nav aria-label="Breadcrumb" style={{ marginBottom: "1rem" }}>
        <Link href="/services">Services</Link>
        <span style={{ color: "var(--text-secondary)" }}>
          {" "}
          / {category.name}
        </span>
      </nav>
      <h1>{category.name}</h1>
      <div className="card" style={{ marginTop: "1rem" }}>
        {category.description ? (
          <p>{category.description}</p>
        ) : (
          <p className="state-text">
            No description has been provided for this service
            category yet.
          </p>
        )}
        <dl className="detail-grid" style={{ marginTop: "1rem" }}>
          <div className="detail-item">
            <dt>Status</dt>
            <dd>
              {category.is_active ? (
                <span className="badge badge-success">Active</span>
              ) : (
                <span className="badge badge-neutral">Inactive</span>
              )}
            </dd>
          </div>
        </dl>
      </div>
      <div className="card" style={{ marginTop: "1rem" }}>
        <h3>How to request this service</h3>
        <p className="state-text" style={{ margin: 0 }}>
          Sign up for an account, then create a service request
          for this category. Providers matched to your request
          will submit quotes for your review.
        </p>
        <div
          style={{
            marginTop: "1rem",
            display: "flex",
            gap: "0.75rem",
            flexWrap: "wrap",
          }}
        >
          <Link className="btn btn-primary" href="/register">
            Create an account
          </Link>
          <Link className="btn btn-outline" href="/how-it-works">
            How it works
          </Link>
        </div>
      </div>
    </div>
  );
}
