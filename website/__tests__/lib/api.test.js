import { api, ApiError } from "@/lib/api";
import { setToken, clearToken, getToken } from "@/lib/auth";

const BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

describe("api client", () => {
  beforeEach(() => {
    clearToken();
    jest.restoreAllMocks();
  });

  test("sends JSON content type and bearer token", async () => {
    setToken("test-token");
    const fetchMock = jest
      .spyOn(global, "fetch")
      .mockResolvedValue(
        new Response(JSON.stringify({ ok: true }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
      );

    await api.get("/service-categories");

    expect(fetchMock).toHaveBeenCalledWith(
      `${BASE}/service-categories`,
      expect.objectContaining({
        headers: expect.objectContaining({
          "Content-Type": "application/json",
          Authorization: "Bearer test-token",
        }),
      })
    );
  });

  test("throws ApiError with backend detail on failure", async () => {
    jest
      .spyOn(global, "fetch")
      .mockResolvedValue(
        new Response(JSON.stringify({ detail: "Not found" }), {
          status: 404,
        })
      );

    await expect(
      api.get("/service-categories/missing")
    ).rejects.toBeInstanceOf(ApiError);
    await expect(
      api.get("/service-categories/missing")
    ).rejects.toThrow("Not found");
  });

  test("clears token on 401 and dispatches event", async () => {
    setToken("expired-token");
    const dispatchSpy = jest.spyOn(window, "dispatchEvent");
    jest
      .spyOn(global, "fetch")
      .mockResolvedValue(new Response(null, { status: 401 }));

    await expect(api.get("/auth/me")).rejects.toThrow(
      "Session expired"
    );

    expect(getToken()).toBeNull();
    expect(dispatchSpy).toHaveBeenCalled();
  });

  test("posts form data as JSON", async () => {
    const fetchMock = jest
      .spyOn(global, "fetch")
      .mockResolvedValue(
        new Response(JSON.stringify({ received: true }), {
          status: 200,
        })
      );

    await api.post("/support/contact", {
      name: "Test",
      subject: "Hello",
    });

    expect(fetchMock).toHaveBeenCalledWith(
      `${BASE}/support/contact`,
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ name: "Test", subject: "Hello" }),
      })
    );
  });
});
