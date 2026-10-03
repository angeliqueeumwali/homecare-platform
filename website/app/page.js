"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import { LoadingState, ErrorState, EmptyState } from "@/components/StateViews";

export default function HomePage() {
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
    <div>
      <section className="hero">
        <div className="container">
          <h1>Home services, requested with confidence</h1>
          <p>
            Homecare Platform connects you with verified local
            service providers. Describe the work you need,
            receive quotes from matched providers, and follow
            every step through to completion.
          </p>
          <div className="hero-actions">
            <Link className="btn btn-primary" href="/services">
              Browse services
            </Link>
            <Link className="btn btn-outline" href="/how-it-works">
              How it works
            </Link>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <h2>Services</h2>
          <p className="state-text">
            Browse the service categories currently available on
            the platform.
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
                  {categories.slice(0, 6).map((category) => (
                    <div className="card" key={category.id}>
                      <h3>{category.name}</h3>
                      <p>{category.description}</p>
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
              {categories.length > 6 && (
                <div style={{ marginTop: "1.5rem" }}>
                  <Link className="btn btn-outline" href="/services">
                    View all services
                  </Link>
                </div>
              )}
            </>
          )}
        </div>
      </section>

      <section className="section section-alt">
        <div className="container">
          <h2>How it works</h2>
          <ol className="steps">
            <li className="step">
              <div className="step-number">1</div>
              <h3>Request a service</h3>
              <p>
                Create an account, choose a service category and
                describe the work including your address and
                preferred date.
              </p>
            </li>
            <li className="step">
              <div className="step-number">2</div>
              <h3>Receive quotes</h3>
              <p>
                The platform matches your request with suitable
                providers who can submit quotes for your review.
              </p>
            </li>
            <li className="step">
              <div className="step-number">3</div>
              <h3>Approve and track</h3>
              <p>
                Approve a quote to assign a provider, then
                follow the request status through completion.
              </p>
            </li>
          </ol>
          <div style={{ marginTop: "1.5rem" }}>
            <Link className="btn btn-primary" href="/how-it-works">
              Learn more
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
