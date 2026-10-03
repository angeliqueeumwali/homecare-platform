"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "./AuthProvider";

export default function ProtectedRoute({ children }) {
  const { user, loading, isAdmin } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !isAdmin) {
      router.replace("/login");
    }
  }, [loading, isAdmin, router]);

  if (loading) {
    return (
      <div className="page-state">
        <div
          className="spinner"
          role="status"
          aria-label="Loading"
        />
      </div>
    );
  }

  if (!isAdmin) {
    return null;
  }

  return children;
}
