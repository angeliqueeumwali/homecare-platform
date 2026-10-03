import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import LoginPage from "@/app/login/page";

const mockLogin = jest.fn();
const mockPush = jest.fn();
const authState = {
  user: null,
  loading: false,
  login: mockLogin,
  register: jest.fn(),
  logout: jest.fn(),
};

jest.mock("next/navigation", () => ({
  useRouter: () => ({ push: mockPush }),
}));

jest.mock("@/components/AuthProvider", () => ({
  useAuth: () => authState,
}));

describe("Login page", () => {
  beforeEach(() => {
    mockLogin.mockReset();
    mockPush.mockReset();
    authState.user = null;
  });

  test("renders the sign-in form", () => {
    render(<LoginPage />);
    expect(screen.getByLabelText(/^email/i)).toBeInTheDocument();
    expect(
      screen.getByLabelText(/^password/i)
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
      await screen.findByText(
        /please enter your email and password/i
      )
    ).toBeInTheDocument();
    expect(mockLogin).not.toHaveBeenCalled();
  });

  test("signs in and redirects to the homepage", async () => {
    const user = userEvent.setup();
    mockLogin.mockResolvedValue({
      id: "1",
      email: "jane@example.com",
      role: "CUSTOMER",
    });
    render(<LoginPage />);

    await user.type(screen.getByLabelText(/^email/i), "jane@example.com");
    await user.type(screen.getByLabelText(/^password/i), "password123");
    await user.click(
      screen.getByRole("button", { name: /sign in/i })
    );

    expect(mockLogin).toHaveBeenCalledWith(
      "jane@example.com",
      "password123"
    );
    expect(mockPush).toHaveBeenCalledWith("/");
  });

  test("shows error on failed authentication", async () => {
    const user = userEvent.setup();
    mockLogin.mockRejectedValue(
      new Error("Invalid credentials")
    );
    render(<LoginPage />);

    await user.type(screen.getByLabelText(/^email/i), "jane@example.com");
    await user.type(screen.getByLabelText(/^password/i), "wrongpassword");
    await user.click(
      screen.getByRole("button", { name: /sign in/i })
    );

    expect(
      await screen.findByText("Invalid credentials")
    ).toBeInTheDocument();
    expect(mockPush).not.toHaveBeenCalled();
  });

  test("shows signed-in state when a session exists", () => {
    authState.user = { email: "jane@example.com" };
    render(<LoginPage />);
    expect(
      screen.getByText(/you are signed in/i)
    ).toBeInTheDocument();
    expect(
      screen.getByText(/jane@example\.com/)
    ).toBeInTheDocument();
  });
});
