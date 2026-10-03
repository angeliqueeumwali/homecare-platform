import { render, screen } from "@testing-library/react";
import RecordsTable, { StatusCell } from "@/components/RecordsTable";

const columns = [
  { key: "name", label: "Name" },
  {
    key: "status",
    label: "Status",
    render: (item) => <StatusCell value={item.status} />,
  },
];

describe("RecordsTable", () => {
  test("renders rows with column data", () => {
    render(
      <RecordsTable
        columns={columns}
        items={[
          { id: "1", name: "Alice", status: "ACTIVE" },
          { id: "2", name: "Bob", status: "PENDING" },
        ]}
        page={1}
        totalPages={1}
        total={2}
        onPageChange={jest.fn()}
      />
    );

    expect(screen.getByText("Alice")).toBeInTheDocument();
    expect(screen.getByText("Bob")).toBeInTheDocument();
    expect(screen.getByText("ACTIVE")).toBeInTheDocument();
    expect(screen.getByText("PENDING")).toBeInTheDocument();
  });

  test("renders empty state when no items", () => {
    render(
      <RecordsTable
        columns={columns}
        items={[]}
        page={1}
        totalPages={0}
        total={0}
        onPageChange={jest.fn()}
        emptyMessage="Nothing here"
      />
    );

    expect(screen.getByText("No records found")).toBeInTheDocument();
    expect(screen.getByText("Nothing here")).toBeInTheDocument();
  });

  test("renders loading state", () => {
    render(
      <RecordsTable
        columns={columns}
        items={[]}
        loading
        page={1}
        totalPages={0}
        total={0}
        onPageChange={jest.fn()}
      />
    );

    expect(
      screen.getByText("Loading records...")
    ).toBeInTheDocument();
  });

  test("renders pagination controls across pages", () => {
    render(
      <RecordsTable
        columns={columns}
        items={[{ id: "1", name: "Alice" }]}
        page={2}
        totalPages={3}
        total={30}
        onPageChange={jest.fn()}
      />
    );

    expect(
      screen.getByText("Page 2 of 3 (30 records)")
    ).toBeInTheDocument();
    expect(
      screen.getByLabelText("Previous page")
    ).toBeInTheDocument();
    expect(screen.getByLabelText("Next page")).toBeInTheDocument();
  });
});
