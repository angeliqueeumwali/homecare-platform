"use client";

import { useAuth } from "./AuthProvider";

export default function TopNav() {
  const { user, logout } = useAuth();

  return (
    <header className="topnav">
      <div className="topnav-title">
        <h1>Administration</h1>
      </div>
      <div className="topnav-user">
        <span className="topnav-email">{user?.email}</span>
        <span className="role-badge">{user?.role}</span>
        <button
          type="button"
          className="btn btn-outline"
          onClick={logout}
        >
          Sign out
        </button>
      </div>
    </header>
  );
}
