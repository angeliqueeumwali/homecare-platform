import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import ConfirmDialog from "@/components/ConfirmDialog";

describe("ConfirmDialog", () => {
  let onConfirm;
  let onCancel;

  beforeEach(() => {
    onConfirm = jest.fn();
    onCancel = jest.fn();
  });

  const defaults = () => ({
    title: "Confirm action",
    message: "Are you sure?",
    onConfirm,
    onCancel,
  });

  test("does not render when closed", () => {
    render(<ConfirmDialog {...defaults()} open={false} />);
    expect(
      screen.queryByRole("alertdialog")
    ).not.toBeInTheDocument();
  });

  test("renders title and message when open", () => {
    render(<ConfirmDialog {...defaults()} open />);
    expect(
      screen.getByRole("alertdialog")
    ).toBeInTheDocument();
    expect(screen.getByText("Confirm action")).toBeInTheDocument();
    expect(screen.getByText("Are you sure?")).toBeInTheDocument();
  });

  test("calls onConfirm and onCancel", async () => {
    const user = userEvent.setup();
    render(<ConfirmDialog {...defaults()} open />);

    await user.click(screen.getByText("Confirm"));
    expect(onConfirm).toHaveBeenCalledTimes(1);

    await user.click(screen.getByText("Cancel"));
    expect(onCancel).toHaveBeenCalledTimes(1);
  });

  test("calls onCancel when Escape is pressed", () => {
    render(<ConfirmDialog {...defaults()} open />);
    window.dispatchEvent(
      new KeyboardEvent("keydown", { key: "Escape" })
    );
    expect(onCancel).toHaveBeenCalledTimes(1);
  });
});
