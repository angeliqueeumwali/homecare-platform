import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import ContactPage from "@/app/contact/page";

describe("Contact page", () => {
  test("renders the contact form", () => {
    render(<ContactPage />);
    expect(screen.getByLabelText(/^name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/^email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/^subject/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/^message/i)).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /send message/i })
    ).toBeInTheDocument();
  });

  test("shows validation errors for invalid input", async () => {
    const user = userEvent.setup();
    render(<ContactPage />);

    await user.type(screen.getByLabelText(/^name/i), "J");
    await user.type(screen.getByLabelText(/^email/i), "not-an-email");
    await user.type(screen.getByLabelText(/^subject/i), "Hi");
    await user.type(screen.getByLabelText(/^message/i), "short");
    await user.click(
      screen.getByRole("button", { name: /send message/i })
    );

    expect(
      await screen.findByText(/please enter your full name/i)
    ).toBeInTheDocument();
    expect(screen.getByText(/valid email address/i)).toBeInTheDocument();
    expect(screen.getByText(/please enter a subject/i)).toBeInTheDocument();
    expect(
      screen.getByText(/at least 10 characters/i)
    ).toBeInTheDocument();
    expect(global.fetch).not.toHaveBeenCalled();
  });

  test("submits valid data and shows honest confirmation", async () => {
    const user = userEvent.setup();
    jest.spyOn(global, "fetch").mockResolvedValue(
      new Response(
        JSON.stringify({ received: true, email_delivery_configured: false }),
        { status: 200 }
      )
    );
    render(<ContactPage />);

    await user.type(screen.getByLabelText(/^name/i), "Jane Doe");
    await user.type(screen.getByLabelText(/^email/i), "jane@example.com");
    await user.type(screen.getByLabelText(/^subject/i), "Question about booking");
    await user.type(
      screen.getByLabelText(/^message/i),
      "I have a question about my recent booking."
    );
    await user.click(
      screen.getByRole("button", { name: /send message/i })
    );

    expect(
      await screen.findByText(/your message was received/i)
    ).toBeInTheDocument();
    expect(
      screen.getByText(/email delivery is not currently configured/i)
    ).toBeInTheDocument();

    const call = global.fetch.mock.calls[0];
    expect(call[1].body).toContain("Jane Doe");
    expect(call[1].method).toBe("POST");
  });

  test("shows error state when submission fails", async () => {
    const user = userEvent.setup();
    jest
      .spyOn(global, "fetch")
      .mockResolvedValue(
        new Response(JSON.stringify({ detail: "Too many messages" }), {
          status: 400,
        })
      );
    render(<ContactPage />);

    await user.type(screen.getByLabelText(/^name/i), "Jane Doe");
    await user.type(screen.getByLabelText(/^email/i), "jane@example.com");
    await user.type(screen.getByLabelText(/^subject/i), "Question about booking");
    await user.type(
      screen.getByLabelText(/^message/i),
      "I have a question about my recent booking."
    );
    await user.click(
      screen.getByRole("button", { name: /send message/i })
    );

    expect(
      await screen.findByText("Too many messages")
    ).toBeInTheDocument();
  });
});
