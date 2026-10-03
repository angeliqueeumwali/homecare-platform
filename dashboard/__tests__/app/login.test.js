import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import LoginPage from "@/app/login/page";

const mockLogin = jest.fn();
const mockReplace = jest.fn();

jest.mock("next/navigation", () => ({
  useRouter: () => ({ replace: mockReplace }),
}));

jest.mock("@/components/AuthProvider", () => ({
  useAuth: () => ({
    login: mockLogin,
    user: null,
    isAdmin: false,
  }),
}));

describe("Admin login page", () => {
  beforeEach(() => {
    mockLogin.mockReset();
    mockReplace.mockReset();
  });

  test("renders the sign-in form", () => {
    render(<LoginPage />);
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(
      screen.getByLabelText(/password/i)
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /sign in/i })
    ).toBeInTheDocument();
  });

  test("shows validation error when fields are empty", async () => {
    const user = userEvent.setup();
    render(<LoginPage />);

    await user.click(
      screen.getByRole("button", { name: /sign in/i })
    );

    expect(
      screen.getByText(/please enter your email and password/i)
    ).toBeInTheDocument();
    expect(mockLogin).not.toHaveBeenCalled();
  });

  test("shows error on failed authentication", async () => {
    const user = userEvent.setup();
    mockLogin.mockRejectedValue(new Error("Invalid credentials"));
    render(<LoginPage />);

    await user.type(screen.getByLabelText(/email/i), "admin@example.com");
    await user.type(screen.getByLabelText(/password/i), "password123");
    await user.click(
      screen.getByRole("button", { name: /sign in/i })
    );

    expect(
      await screen.findByText("Invalid credentials")
    ).toBeInTheDocument();
    expect(mockReplace).not.toHaveBeenCalled();
  });

  test("rejects non-admin accounts", async () => {
    const user = userEvent.setup();
    mockLogin.mockResolvedValue({
      id: "1",
      email: "customer@example.com",
      role: "CUSTOMER",
    });
    render(<LoginPage />);

    await user.type(screen.getByLabelText(/email/i), "customer@example.com");
    await user.type(screen.getByLabelText(/password/i), "password123");
    await user.click(
      screen.getByRole("button", { name: /sign in/i })
    );

    expect(
      await screen.findByText(
        /access denied/i
      )
    ).toBeInTheDocument();
    expect(mockReplace).not.toHaveBeenCalled();
  });

  test("redirects admins to the overview", async () => {
    const user = userEvent.setup();
    mockLogin.mockResolvedValue({
      id: "1",
      email: "admin@example.com",
      role: "ADMIN",
    });
    render(<LoginPage />);

    await user.type(screen.getByLabelText(/email/i), "admin@example.com");
    await user.type(screen.getByLabelText(/password/i), "password123");
    await user.click(
      screen.getByRole("button", { name: /sign in/i })
    );

    expect(mockReplace).toHaveBeenCalledWith("/overview");
  });
});
