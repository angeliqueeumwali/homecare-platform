"use client";

import { useState } from "react";
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
  const [menuOpen, setMenuOpen] = useState(false);

  function navigate(href) {
    setMenuOpen(false);
    if (href) {
      router.push(href);
    }
  }

  return (
    <header className="navbar">
      <div className="container navbar-inner">
        <Link className="navbar-brand" href="/" onClick={() => setMenuOpen(false)}>
          <span className="brand-mark" aria-hidden="true">
            HC
          </span>
          Homecare
        </Link>
        <button
          type="button"
          className="menu-toggle"
          aria-expanded={menuOpen}
          aria-controls="primary-nav"
          aria-label={menuOpen ? "Close menu" : "Open menu"}
          onClick={() => setMenuOpen((open) => !open)}
        >
          <span className="hamburger" aria-hidden="true" />
        </button>
        <nav
          id="primary-nav"
          className={`primary-nav${menuOpen ? " open" : ""}`}
          aria-label="Main"
        >
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
                  onClick={() => setMenuOpen(false)}
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
                  setMenuOpen(false);
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
