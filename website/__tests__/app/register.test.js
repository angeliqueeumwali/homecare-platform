import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import RegisterPage from "@/app/register/page";

const mockRegister = jest.fn();
const mockPush = jest.fn();

jest.mock("next/navigation", () => ({
  useRouter: () => ({ push: mockPush }),
}));

jest.mock("@/components/AuthProvider", () => ({
  useAuth: () => ({ register: mockRegister }),
}));

describe("Register page", () => {
  beforeEach(() => {
    mockRegister.mockReset();
  });

  test("renders the registration form", () => {
    render(<RegisterPage />);
    expect(
      screen.getByLabelText(/first name/i)
    ).toBeInTheDocument();
    expect(
      screen.getByLabelText(/last name/i)
    ).toBeInTheDocument();
    expect(screen.getByLabelText(/^email/i)).toBeInTheDocument();
    expect(
      screen.getByLabelText(/phone number/i)
    ).toBeInTheDocument();
    expect(
      screen.getByLabelText(/^password/i)
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /register/i })
    ).toBeInTheDocument();
  });

  test("validates fields before submitting", async () => {
    const user = userEvent.setup();
    render(<RegisterPage />);

    await user.click(
      screen.getByRole("button", { name: /register/i })
    );

    expect(
      await screen.findByText(/first name is required/i)
    ).toBeInTheDocument();
    expect(screen.getByText(/last name is required/i)).toBeInTheDocument();
    expect(screen.getByText(/valid email address/i)).toBeInTheDocument();
    expect(screen.getByText(/valid phone number/i)).toBeInTheDocument();
    expect(
      screen.getByText(/password must be at least 8 characters/i)
    ).toBeInTheDocument();
    expect(mockRegister).not.toHaveBeenCalled();
  });

  test("rejects mismatched passwords", async () => {
    const user = userEvent.setup();
    render(<RegisterPage />);

    await user.type(screen.getByLabelText(/first name/i), "Jane");
    await user.type(screen.getByLabelText(/last name/i), "Doe");
    await user.type(screen.getByLabelText(/^email/i), "jane@example.com");
    await user.type(screen.getByLabelText(/phone number/i), "0780000000");
    await user.type(screen.getByLabelText(/^password/i), "password123");
    await user.type(
      screen.getByLabelText(/confirm password/i),
      "different123"
    );
    await user.click(
      screen.getByRole("button", { name: /register/i })
    );

    expect(
      await screen.findByText(/passwords do not match/i)
    ).toBeInTheDocument();
    expect(mockRegister).not.toHaveBeenCalled();
  });

  test("registers with the backend and shows success", async () => {
    const user = userEvent.setup();
    mockRegister.mockResolvedValue({ id: "1", role: "CUSTOMER" });
    render(<RegisterPage />);

    await user.type(screen.getByLabelText(/first name/i), "Jane");
    await user.type(screen.getByLabelText(/last name/i), "Doe");
    await user.type(screen.getByLabelText(/^email/i), "jane@example.com");
    await user.type(screen.getByLabelText(/phone number/i), "0780000000");
    await user.type(screen.getByLabelText(/^password/i), "password123");
    await user.type(
      screen.getByLabelText(/confirm password/i),
      "password123"
    );
    await user.click(
      screen.getByRole("button", { name: /register/i })
    );

    expect(
      await screen.findByText(/your account was created/i)
    ).toBeInTheDocument();
    expect(mockRegister).toHaveBeenCalledWith(
      "Jane",
      "Doe",
      "jane@example.com",
      "0780000000",
      "password123"
    );
  });

  test("shows backend errors", async () => {
    const user = userEvent.setup();
    mockRegister.mockRejectedValue(
      new Error("Email already registered")
    );
    render(<RegisterPage />);

    await user.type(screen.getByLabelText(/first name/i), "Jane");
    await user.type(screen.getByLabelText(/last name/i), "Doe");
    await user.type(screen.getByLabelText(/^email/i), "jane@example.com");
    await user.type(screen.getByLabelText(/phone number/i), "0780000000");
    await user.type(screen.getByLabelText(/^password/i), "password123");
    await user.type(
      screen.getByLabelText(/confirm password/i),
      "password123"
    );
    await user.click(
      screen.getByRole("button", { name: /register/i })
    );

    expect(
      await screen.findByText("Email already registered")
    ).toBeInTheDocument();
  });
});
