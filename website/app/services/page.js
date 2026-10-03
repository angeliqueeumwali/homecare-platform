"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import { LoadingState, ErrorState, EmptyState } from "@/components/StateViews";

export default function ServicesPage() {
  const [categories, setCategories] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const data = await api.get("/service-categories");
      setCategories((data || []).filter((c) => c.is_active));
    } catch (err) {
      setError(err.message || "Failed to load services.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div className="container section">
      <h1>Services</h1>
      <p className="state-text">
        Choose a service category to see what the platform
        supports.
      </p>
      {loading && <LoadingState label="Loading services..." />}
      {error && <ErrorState message={error} onRetry={load} />}
      {!loading && !error && categories && (
        <>
          {categories.length === 0 ? (
            <EmptyState
              title="No services listed"
              message="Service categories have not been published yet."
            />
          ) : (
            <div className="card-grid">
              {categories.map((category) => (
                <div className="card" key={category.id}>
                  <h3>{category.name}</h3>
                  <p>{category.description || "No description provided."}</p>
                  <Link
                    className="card-link"
                    href={`/services/${category.id}`}
                  >
                    View details
                  </Link>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
