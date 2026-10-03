import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import OverviewPage from "@/app/(dashboard)/overview/page";

const statsPayload = {
  customers_total: 4,
  providers_total: 2,
  providers_pending_approval: 1,
  requests_total: 7,
  requests_pending: 2,
  requests_in_progress: 3,
  requests_completed: 2,
  requests_cancelled: 0,
  quotes_pending: 1,
  quotes_approved: 2,
  quotes_rejected: 0,
  payments_total: 5,
  payments_pending: 1,
  payments_paid: 4,
  reviews_total: 3,
  issues_total: 2,
  issues_open: 1,
  assignments_total: 6,
  notifications_total: 9,
};

describe("Overview page", () => {
  test("displays real statistics from the API", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      new Response(JSON.stringify(statsPayload), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    );

    render(<OverviewPage />);

    expect(
      await screen.findByText("Platform overview")
    ).toBeInTheDocument();
    expect(screen.getByText("Customers")).toBeInTheDocument();
    expect(screen.getByText("4")).toBeInTheDocument();
    expect(screen.getByText("Pending approvals")).toBeInTheDocument();
    expect(screen.getByText("Open issues")).toBeInTheDocument();
    expect(screen.getAllByText("1").length).toBeGreaterThan(0);
  });

  test("shows error state when the API fails", async () => {
    jest
      .spyOn(global, "fetch")
      .mockResolvedValue(new Response(null, { status: 500 }));

    render(<OverviewPage />);

    expect(
      await screen.findByText(/something went wrong/i)
    ).toBeInTheDocument();
    expect(
      screen.getByText(/request failed with status 500/i)
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /try again/i })
    ).toBeInTheDocument();
  });
});
