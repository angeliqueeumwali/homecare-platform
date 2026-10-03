import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import Navbar from "@/components/Navbar";
import { usePathname, useRouter } from "next/navigation";

const mockPush = jest.fn();
const authState = {
  user: null,
  loading: false,
  login: jest.fn(),
  register: jest.fn(),
  logout: jest.fn(),
};

jest.mock("next/navigation", () => ({
  usePathname: () => "/",
  useRouter: () => ({ push: mockPush }),
}));

jest.mock("@/lib/auth", () => ({
  getToken: () => null,
  clearToken: jest.fn(),
  setToken: jest.fn(),
  getStoredUser: () => null,
  setStoredUser: jest.fn(),
  clearStoredUser: jest.fn(),
}));

jest.mock("@/components/AuthProvider", () => ({
  AuthProvider: ({ children }) => children,
  useAuth: () => authState,
}));

describe("Navbar", () => {
  beforeEach(() => {
    authState.user = null;
    mockPush.mockReset();
    authState.logout.mockReset();
  });

  test("renders navigation links", () => {
    render(<Navbar />);
    expect(
      screen.getByRole("link", { name: "Home", exact: true })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /services/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /how it works/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /about/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /faq/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /contact/i })
    ).toBeInTheDocument();
  });

  test("shows sign in and register when signed out", () => {
    render(<Navbar />);
    expect(
      screen.getByRole("link", { name: /sign in/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /register/i })
    ).toBeInTheDocument();
  });

  test("shows user email and sign out when signed in", async () => {
    const user = userEvent.setup();
    authState.user = { email: "customer@example.com" };
    render(<Navbar />);

    expect(
      screen.getByText("customer@example.com")
    ).toBeInTheDocument();
    await user.click(
      screen.getByRole("button", { name: /sign out/i })
    );

    expect(authState.logout).toHaveBeenCalled();
    expect(mockPush).toHaveBeenCalledWith("/");
  });
});
