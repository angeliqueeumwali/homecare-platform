"use client";

import Sidebar from "@/components/Sidebar";
import TopNav from "@/components/TopNav";
import ProtectedRoute from "@/components/ProtectedRoute";

export default function DashboardLayout({ children }) {
  return (
    <ProtectedRoute>
      <div className="shell">
        <Sidebar />
        <div className="shell-main">
          <TopNav />
          <main className="shell-content">{children}</main>
        </div>
      </div>
    </ProtectedRoute>
  );
}
