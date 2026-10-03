"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { api } from "@/lib/api";

const DEFAULTS = {
  page: 1,
  page_size: 20,
};

export function usePaginatedList(endpoint, extraDefaults = {}) {
  const [params, setParams] = useState({
    ...DEFAULTS,
    ...extraDefaults,
  });
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const requestId = useRef(0);

  const load = useCallback(async () => {
    const id = (requestId.current += 1);
    setLoading(true);
    setError("");
    try {
      const query = new URLSearchParams();
      Object.entries(params).forEach(([key, value]) => {
        if (value !== "" && value !== null && value !== undefined) {
          query.set(key, String(value));
        }
      });
      const result = await api.get(
        `${endpoint}?${query.toString()}`
      );
      if (requestId.current === id) {
        setData(result);
      }
    } catch (err) {
      if (requestId.current === id) {
        setError(err.message || "Failed to load records.");
      }
    } finally {
      if (requestId.current === id) {
        setLoading(false);
      }
    }
  }, [endpoint, params]);

  useEffect(() => {
    load();
  }, [load]);

  const update = useCallback(
    (changes) => {
      setParams((current) => ({
        ...current,
        ...changes,
        page:
          "page" in changes
            ? changes.page
            : 1,
      }));
    },
    []
  );

  return { params, data, loading, error, update, reload: load };
}
