"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import { LoadingState, ErrorState } from "@/components/StateViews";

const STAT_CARDS = [
  ["Customers", "customers_total"],
  ["Providers", "providers_total"],
  ["Pending approvals", "providers_pending_approval"],
  ["Service requests", "requests_total"],
  ["In progress", "requests_in_progress"],
  ["Completed requests", "requests_completed"],
  ["Pending quotes", "quotes_pending"],
  ["Payments", "payments_total"],
  ["Reviews", "reviews_total"],
  ["Open issues", "issues_open"],
  ["Assignments", "assignments_total"],
  ["Notifications", "notifications_total"],
];

export default function OverviewPage() {
  const [stats, setStats] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const data = await api.get("/admin/stats");
      setStats(data);
    } catch (err) {
      setError(err.message || "Failed to load statistics.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  if (loading) return <LoadingState label="Loading statistics..." />;
  if (error)
    return <ErrorState message={error} onRetry={load} />;

  return (
    <div>
      <div className="card-header">
        <h2>Platform overview</h2>
      </div>
      <div className="stat-grid">
        {STAT_CARDS.map(([label, key]) => (
          <div className="stat-card" key={key}>
            <p className="stat-label">{label}</p>
            <p className="stat-value">{stats[key] ?? 0}</p>
          </div>
        ))}
      </div>
      <div className="card">
        <div className="card-header">
          <h3>Quick access</h3>
        </div>
        <p className="state-text" style={{ margin: 0 }}>
          Use the sidebar to manage users, providers, service
          requests, quotes, payments, reviews, issues,
          notifications and contact messages.
        </p>
        <div style={{ marginTop: "1rem", display: "flex", gap: "0.75rem", flexWrap: "wrap" }}>
          <Link className="btn btn-outline" href="/providers">
            Review pending providers
          </Link>
          <Link className="btn btn-outline" href="/issues">
            View open issues
          </Link>
        </div>
      </div>
    </div>
  );
}
