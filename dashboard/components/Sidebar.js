"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV = [
  { href: "/overview", label: "Overview" },
  { href: "/users", label: "Users" },
  { href: "/providers", label: "Providers" },
  { href: "/service-requests", label: "Service Requests" },
  { href: "/quotes", label: "Quotes" },
  { href: "/payments", label: "Payments" },
  { href: "/reviews", label: "Reviews" },
  { href: "/issues", label: "Issues" },
  { href: "/notifications", label: "Notifications" },
  { href: "/contact-messages", label: "Contact Messages" },
  { href: "/settings", label: "Settings" },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <span className="brand-mark" aria-hidden="true">
          HC
        </span>
        <div>
          <p className="brand-name">Homecare</p>
          <p className="brand-sub">Admin Dashboard</p>
        </div>
      </div>
      <nav className="sidebar-nav" aria-label="Admin">
        {NAV.map((item) => {
          const active =
            item.href === "/overview"
              ? pathname === "/overview" || pathname === "/"
              : pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={active ? "nav-link active" : "nav-link"}
              aria-current={active ? "page" : undefined}
            >
              {item.label}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
