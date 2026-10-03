"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "./AuthProvider";

const LINKS = [
  { href: "/", label: "Home" },
  { href: "/services", label: "Services" },
  { href: "/how-it-works", label: "How it works" },
  { href: "/about", label: "About" },
  { href: "/faq", label: "FAQ" },
  { href: "/contact", label: "Contact" },
];

export default function Navbar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuth();

  return (
    <header className="navbar">
      <div className="container navbar-inner">
        <Link className="navbar-brand" href="/">
          <span className="brand-mark" aria-hidden="true">
            HC
          </span>
          Homecare
        </Link>
        <nav aria-label="Main">
          <ul className="navbar-links">
            {LINKS.map((link) => (
              <li key={link.href}>
                <Link
                  href={link.href}
                  className={
                    pathname === link.href ? "active" : undefined
                  }
                  aria-current={
                    pathname === link.href ? "page" : undefined
                  }
                >
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
        <div className="navbar-actions">
          {user ? (
            <div className="user-menu">
              <span className="user-email">{user.email}</span>
              <button
                type="button"
                className="btn btn-outline btn-sm"
                onClick={() => {
                  logout();
                  router.push("/");
                }}
              >
                Sign out
              </button>
            </div>
          ) : (
            <>
              <Link className="btn btn-outline btn-sm" href="/login">
                Sign in
              </Link>
              <Link className="btn btn-primary btn-sm" href="/register">
                Register
              </Link>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
