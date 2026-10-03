import Link from "next/link";

export default function Footer() {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-inner">
          <div style={{ maxWidth: "320px" }}>
            <div
              className="navbar-brand"
              style={{ marginBottom: "0.75rem" }}
            >
              <span className="brand-mark" aria-hidden="true">
                HC
              </span>
              Homecare
            </div>
            <p>
              A platform for requesting trusted home services in
              your neighborhood.
            </p>
          </div>
          <div>
            <h4>Platform</h4>
            <Link href="/services">Services</Link>
            <Link href="/how-it-works">How it works</Link>
            <Link href="/faq">FAQ</Link>
          </div>
          <div>
            <h4>Company</h4>
            <Link href="/about">About</Link>
            <Link href="/contact">Contact</Link>
          </div>
          <div>
            <h4>Account</h4>
            <Link href="/register">Register</Link>
            <Link href="/login">Sign in</Link>
          </div>
        </div>
        <div className="footer-bottom">
          <p style={{ margin: 0 }}>
            Homecare Platform. All information on this site is
            provided for general purposes only.
          </p>
        </div>
      </div>
    </footer>
  );
}
