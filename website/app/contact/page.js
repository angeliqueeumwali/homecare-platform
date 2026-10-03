"use client";

import { useState } from "react";
import { api } from "@/lib/api";

export default function ContactPage() {
  const [form, setForm] = useState({
    name: "",
    email: "",
    subject: "",
    message: "",
    honeypot: "",
  });
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  const [status, setStatus] = useState(null);

  function validate() {
    const next = {};
    if (form.name.trim().length < 2) {
      next.name = "Please enter your full name.";
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
      next.email = "Please enter a valid email address.";
    }
    if (form.subject.trim().length < 3) {
      next.subject = "Please enter a subject.";
    }
    if (form.message.trim().length < 10) {
      next.message =
        "Please enter a message of at least 10 characters.";
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
      await api.post("/support/contact", {
        name: form.name.trim(),
        email: form.email.trim(),
        subject: form.subject.trim(),
        message: form.message.trim(),
        honeypot: form.honeypot,
      });
      setStatus({
        type: "success",
        text: "Your message was received and recorded by the platform. Our support team reviews contact messages through the admin dashboard. Email delivery is not currently configured, so you will not receive an email confirmation.",
      });
      setForm({
        name: "",
        email: "",
        subject: "",
        message: "",
        honeypot: "",
      });
    } catch (err) {
      setStatus({
        type: "error",
        text: err.message || "Failed to send your message. Please try again.",
      });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="container section">
      <h1>Contact us</h1>
      <p>
        Questions about a service request, your account or
        the platform? Send us a message.
      </p>
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
            <label className="form-label" htmlFor="name">
              Name
            </label>
            <input
              id="name"
              className="form-control"
              type="text"
              value={form.name}
              onChange={(event) =>
                setForm({ ...form, name: event.target.value })
              }
              required
            />
            {errors.name && (
              <p className="form-error">{errors.name}</p>
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
            />
            {errors.email && (
              <p className="form-error">{errors.email}</p>
            )}
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="subject">
              Subject
            </label>
            <input
              id="subject"
              className="form-control"
              type="text"
              value={form.subject}
              onChange={(event) =>
                setForm({ ...form, subject: event.target.value })
              }
              required
            />
            {errors.subject && (
              <p className="form-error">{errors.subject}</p>
            )}
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="message">
              Message
            </label>
            <textarea
              id="message"
              className="form-textarea"
              value={form.message}
              onChange={(event) =>
                setForm({ ...form, message: event.target.value })
              }
              required
            />
            {errors.message && (
              <p className="form-error">{errors.message}</p>
            )}
          </div>
          <div
            className="form-group"
            style={{ position: "absolute", left: "-9999px" }}
            aria-hidden="true"
          >
            <label className="form-label" htmlFor="website">
              Website
            </label>
            <input
              id="website"
              className="form-control"
              type="text"
              tabIndex={-1}
              autoComplete="off"
              value={form.honeypot}
              onChange={(event) =>
                setForm({ ...form, honeypot: event.target.value })
              }
            />
          </div>
          <button
            type="submit"
            className="btn btn-primary"
            disabled={submitting}
            style={{ width: "100%" }}
          >
            {submitting ? "Sending..." : "Send message"}
          </button>
        </form>
      </div>
    </div>
  );
}
