"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useAuth } from "@/components/AuthProvider";

export default function RegisterPage() {
  const { register } = useAuth();
  const router = useRouter();
  const [form, setForm] = useState({
    first_name: "",
    last_name: "",
    email: "",
    phone_number: "",
    password: "",
    confirm_password: "",
  });
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  const [status, setStatus] = useState(null);

  function validate() {
    const next = {};
    if (form.first_name.trim().length < 2) {
      next.first_name = "First name is required.";
    }
    if (form.last_name.trim().length < 2) {
      next.last_name = "Last name is required.";
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
      next.email = "Please enter a valid email address.";
    }
    if (form.phone_number.trim().length < 7) {
      next.phone_number = "Please enter a valid phone number.";
    }
    if (form.password.length < 8) {
      next.password = "Password must be at least 8 characters.";
    }
    if (form.confirm_password !== form.password) {
      next.confirm_password = "Passwords do not match.";
    }
    setErrors(next);
    return Object.keys(next).length === 0;
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setStatus(null);
    if (!validate()) return;

    setSubmitting(true);
    try {
      await register(
        form.first_name.trim(),
        form.last_name.trim(),
        form.email.trim(),
        form.phone_number.trim(),
        form.password
      );
      setStatus({
        type: "success",
        text: "Your account was created successfully. Please sign in to request a service.",
      });
      setTimeout(() => router.push("/login"), 1500);
    } catch (err) {
      setStatus({
        type: "error",
        text: err.message || "Registration failed. Please try again.",
      });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="container section">
      <h1>Create an account</h1>
      <p>Register to request home services on the platform.</p>
      <div className="form-card" style={{ margin: "1.5rem auto" }}>
        {status && (
          <div
            className={`alert alert-${status.type}`}
            role="alert"
          >
            {status.text}
          </div>
        )}
        <form onSubmit={handleSubmit} noValidate>
          <div className="form-group">
            <label className="form-label" htmlFor="first_name">
              First name
            </label>
            <input
              id="first_name"
              className="form-control"
              type="text"
              value={form.first_name}
              onChange={(event) =>
                setForm({ ...form, first_name: event.target.value })
              }
              required
            />
            {errors.first_name && (
              <p className="form-error">{errors.first_name}</p>
            )}
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="last_name">
              Last name
            </label>
            <input
              id="last_name"
              className="form-control"
              type="text"
              value={form.last_name}
              onChange={(event) =>
                setForm({ ...form, last_name: event.target.value })
              }
              required
            />
            {errors.last_name && (
              <p className="form-error">{errors.last_name}</p>
            )}
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              className="form-control"
              type="email"
              value={form.email}
              onChange={(event) =>
                setForm({ ...form, email: event.target.value })
              }
              required
              autoComplete="email"
            />
            {errors.email && (
              <p className="form-error">{errors.email}</p>
            )}
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="phone_number">
              Phone number
            </label>
            <input
              id="phone_number"
              className="form-control"
              type="tel"
              value={form.phone_number}
              onChange={(event) =>
                setForm({ ...form, phone_number: event.target.value })
              }
              required
            />
            {errors.phone_number && (
              <p className="form-error">{errors.phone_number}</p>
            )}
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="password">
              Password
            </label>
            <input
              id="password"
              className="form-control"
              type="password"
              value={form.password}
              onChange={(event) =>
                setForm({ ...form, password: event.target.value })
              }
              required
              autoComplete="new-password"
            />
            {errors.password && (
              <p className="form-error">{errors.password}</p>
            )}
            <p className="form-hint">
              At least 8 characters.
            </p>
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="confirm_password">
              Confirm password
            </label>
            <input
              id="confirm_password"
              className="form-control"
              type="password"
              value={form.confirm_password}
              onChange={(event) =>
                setForm({
                  ...form,
                  confirm_password: event.target.value,
                })
              }
              required
              autoComplete="new-password"
            />
            {errors.confirm_password && (
              <p className="form-error">{errors.confirm_password}</p>
            )}
          </div>
          <button
            type="submit"
            className="btn btn-primary"
            disabled={submitting}
            style={{ width: "100%" }}
          >
            {submitting ? "Creating account..." : "Register"}
          </button>
        </form>
        <p className="form-hint" style={{ marginTop: "1rem" }}>
          Already have an account? <Link href="/login">Sign in</Link>
        </p>
      </div>
    </div>
  );
}
