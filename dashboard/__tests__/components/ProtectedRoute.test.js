import { render, screen } from "@testing-library/react";
import ProtectedRoute from "@/components/ProtectedRoute";

const mockReplace = jest.fn();
const authState = {
  user: null,
  loading: false,
  isAdmin: false,
};

jest.mock("next/navigation", () => ({
  useRouter: () => ({ replace: mockReplace }),
}));

jest.mock("@/components/AuthProvider", () => ({
  useAuth: () => authState,
}));

function renderProtected() {
  return render(
    <ProtectedRoute>
      <div>Admin content</div>
    </ProtectedRoute>
  );
}

describe("ProtectedRoute", () => {
  beforeEach(() => {
    mockReplace.mockReset();
    authState.user = null;
    authState.loading = false;
    authState.isAdmin = false;
  });

  test("redirects unauthenticated users to login", () => {
    renderProtected();
    expect(mockReplace).toHaveBeenCalledWith("/login");
    expect(
      screen.queryByText("Admin content")
    ).not.toBeInTheDocument();
  });

  test("redirects non-admin users to login", () => {
    authState.user = { role: "CUSTOMER" };
    renderProtected();
    expect(mockReplace).toHaveBeenCalledWith("/login");
    expect(
      screen.queryByText("Admin content")
    ).not.toBeInTheDocument();
  });

  test("shows loading state while restoring session", () => {
    authState.loading = true;
    renderProtected();
    expect(screen.getByLabelText(/loading/i)).toBeInTheDocument();
    expect(mockReplace).not.toHaveBeenCalled();
  });

  test("renders children for admin users", () => {
    authState.user = { role: "ADMIN" };
    authState.isAdmin = true;
    renderProtected();
    expect(
      screen.getByText("Admin content")
    ).toBeInTheDocument();
    expect(mockReplace).not.toHaveBeenCalled();
  });
});
