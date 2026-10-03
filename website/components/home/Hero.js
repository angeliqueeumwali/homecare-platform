import Link from "next/link";

export default function Hero() {
  return (
    <section className="hero-home">
      <div className="container hero-grid">
        <div className="hero-copy">
          <h1>
            Trusted home services, requested with
            confidence
          </h1>
          <p>
            Homecare Platform connects you with local
            service providers for the care and household
            help you need. Describe the work once, receive
            quotes from matched providers, and follow every
            step through to completion.
          </p>
          <div className="hero-actions">
            <Link className="btn btn-primary btn-lg" href="/register">
              Get Started
            </Link>
            <Link className="btn btn-outline btn-lg" href="/services">
              Explore Services
            </Link>
          </div>
          <ul className="hero-points">
            <li>
              Browse care and household service categories
              with clear descriptions
            </li>
            <li>
              Receive itemized quotes and approve the one
              that fits before work begins
            </li>
            <li>
              Track each request from pending to completed
              and review your provider
            </li>
          </ul>
        </div>
        <div className="hero-media">
          <img
            className="hero-image"
            src="/images/hero-home.svg"
            alt="A welcoming home cared for by Homecare Platform"
          />
          <div className="hero-badge">
            <span className="hero-badge-icon" aria-hidden="true">
              &#10003;
            </span>
            <div>
              <strong>Requests tracked end to end</strong>
              <span>From first quote to completion</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
