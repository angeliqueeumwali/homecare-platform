"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useAuth } from "@/components/AuthProvider";

export default function LoginPage() {
  const { login, user } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    setError("");

    if (!email.trim() || !password) {
      setError("Please enter your email and password.");
      return;
    }

    setSubmitting(true);
    try {
      await login(email.trim(), password);
      router.push("/");
    } catch (err) {
      setError(
        err.message || "Sign in failed. Please check your credentials."
      );
    } finally {
      setSubmitting(false);
    }
  }

  if (user && !submitting) {
    return (
      <div className="container section">
        <div className="form-card">
          <h1 style={{ textAlign: "center" }}>You are signed in</h1>
          <p className="state-text" style={{ textAlign: "center" }}>
            Signed in as {user.email}.
          </p>
          <div style={{ textAlign: "center", marginTop: "1rem" }}>
            <Link className="btn btn-primary" href="/">
              Go to homepage
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="auth-layout">
      <div className="auth-side">
        <img
          src="/images/auth-illustration.svg"
          alt="Homecare Platform illustration of a cared-for home"
        />
        <h1>Welcome back</h1>
        <p>
          Sign in to request services, review quotes and
          track your requests.
        </p>
      </div>
      <div className="auth-form-wrap">
        <div className="form-card">
          <h1>Sign in</h1>
          <p style={{ color: "var(--text-secondary)", marginTop: "-0.4rem" }}>
            Access your account to manage your services.
          </p>
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
                className="form-control"
                type="email"
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
                className="form-control"
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                required
                autoComplete="current-password"
              />
            </div>
            <button
              type="submit"
              className="btn btn-primary btn-lg"
              disabled={submitting}
              style={{ width: "100%" }}
            >
              {submitting ? "Signing in..." : "Sign in"}
            </button>
          </form>
          <p className="form-hint" style={{ marginTop: "1.2rem", textAlign: "center" }}>
            Don&apos;t have an account? <Link href="/register">Register</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
