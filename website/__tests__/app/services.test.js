import { render, screen } from "@testing-library/react";
import ServicesPage from "@/app/services/page";

const categories = [
  {
    id: "11111111-1111-1111-1111-111111111111",
    name: "Plumbing",
    description: "Repairs and installations",
    image_url: null,
    is_active: true,
  },
  {
    id: "22222222-2222-2222-2222-222222222222",
    name: "Cleaning",
    description: "Home cleaning",
    image_url: null,
    is_active: true,
  },
];

describe("Services page", () => {
  test("shows loading state first", () => {
    jest.spyOn(global, "fetch").mockImplementation(
      () => new Promise(() => {})
    );
    render(<ServicesPage />);
    expect(
      screen.getByText(/loading services/i)
    ).toBeInTheDocument();
  });

  test("renders active categories from the API", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      new Response(JSON.stringify(categories), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    );
    render(<ServicesPage />);

    expect(await screen.findByText("Plumbing")).toBeInTheDocument();
    expect(screen.getByText("Cleaning")).toBeInTheDocument();
    expect(screen.getByText("Repairs and installations")).toBeInTheDocument();
    expect(
      screen.getAllByRole("link", { name: /view details/i }).length
    ).toBeGreaterThan(0);
  });

  test("hides inactive categories", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      new Response(
        JSON.stringify([
          ...categories,
          {
            id: "33333333-3333-3333-3333-333333333333",
            name: "Removed",
            description: "Hidden",
            image_url: null,
            is_active: false,
          },
        ]),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      )
    );
    render(<ServicesPage />);

    expect(await screen.findByText("Plumbing")).toBeInTheDocument();
    expect(
      screen.queryByText("Removed")
    ).not.toBeInTheDocument();
  });

  test("shows empty state when no categories", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      new Response(JSON.stringify([]), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    );
    render(<ServicesPage />);

    expect(
      await screen.findByText("No services listed")
    ).toBeInTheDocument();
  });

  test("shows error state when the API fails", async () => {
    jest
      .spyOn(global, "fetch")
      .mockResolvedValue(new Response(null, { status: 500 }));
    render(<ServicesPage />);

    expect(
      await screen.findByText(/something went wrong/i)
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /try again/i })
    ).toBeInTheDocument();
  });
});
