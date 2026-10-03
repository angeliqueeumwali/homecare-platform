"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/components/AuthProvider";

export default function LoginPage() {
  const { login, user, isAdmin } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (isAdmin) {
      router.replace("/overview");
    } else if (user) {
      setError(
        "This dashboard is restricted to administrators."
      );
    }
  }, [isAdmin, user, router]);

  async function handleSubmit(event) {
    event.preventDefault();
    setError("");

    if (!email.trim() || !password) {
      setError("Please enter your email and password.");
      return;
    }

    setSubmitting(true);
    try {
      const me = await login(email.trim(), password);
      if (me.role !== "ADMIN") {
        setError(
          "Access denied. Administrator privileges are required."
        );
        return;
      }
      router.replace("/overview");
    } catch (err) {
      setError(err.message || "Sign in failed. Please try again.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login-shell">
      <div className="login-card">
        <div className="login-brand">
          <span className="brand-mark" aria-hidden="true">
            HC
          </span>
          <h1>Homecare Admin</h1>
          <p className="form-hint">
            Sign in to manage the platform
          </p>
        </div>
        {error && (
          <div className="alert alert-error" role="alert">
            {error}
          </div>
        )}
        <form onSubmit={handleSubmit} noValidate>
          <div className="form-group">
            <label className="form-label" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              className="form-control"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              required
              autoComplete="email"
            />
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="password">
              Password
            </label>
            <input
              id="password"
              type="password"
              className="form-control"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
              autoComplete="current-password"
            />
          </div>
          <button
            type="submit"
            className="btn btn-primary"
            disabled={submitting}
            style={{ width: "100%" }}
          >
            {submitting ? "Signing in..." : "Sign in"}
          </button>
        </form>
        <p className="form-hint" style={{ marginTop: "1rem" }}>
          Need a customer or provider account? Use the public
          website.
        </p>
      </div>
    </div>
  );
}
