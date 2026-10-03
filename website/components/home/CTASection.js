import Link from "next/link";

export default function CTASection() {
  return (
    <section className="cta-section">
      <div className="container">
        <div className="cta-card">
          <h2>Need help at home?</h2>
          <p>
            Create an account, describe the work you need,
            and receive quotes from matched providers today.
          </p>
          <div className="hero-actions" style={{ justifyContent: "center" }}>
            <Link className="btn btn-primary btn-lg" href="/register">
              Get Started
            </Link>
            <Link className="btn btn-outline btn-lg" href="/services">
              Explore Services
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}
