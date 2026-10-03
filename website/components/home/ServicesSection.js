"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import ServiceCard from "@/components/home/ServiceCard";
import SectionHeading from "@/components/SectionHeading";
import { LoadingState, ErrorState, EmptyState } from "@/components/StateViews";

export default function ServicesSection() {
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
    <section className="section section-alt">
      <div className="container">
        <SectionHeading
          title="Our services"
          lead="Care and household services from local providers, all requested through one platform."
        />
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
              <div className="service-grid">
                {categories.slice(0, 6).map((category) => (
                  <ServiceCard key={category.id} category={category} />
                ))}
              </div>
            )}
            {categories.length > 6 && (
              <div className="section-more">
                <Link className="btn btn-outline btn-lg" href="/services">
                  View all services
                </Link>
              </div>
            )}
          </>
        )}
      </div>
    </section>
  );
}
