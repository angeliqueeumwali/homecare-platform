import { render, screen } from "@testing-library/react";
import HomePage from "@/app/page";

const categories = [
  {
    id: "11111111-1111-1111-1111-111111111111",
    name: "Child Care",
    description: "Home-based childcare",
    is_active: true,
  },
  {
    id: "22222222-2222-2222-2222-222222222222",
    name: "Elderly Care",
    description: "Daily routines and support",
    is_active: true,
  },
];

describe("Home page", () => {
  test("renders hero with primary and secondary CTAs", () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      new Response(JSON.stringify(categories), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    );
    render(<HomePage />);

    expect(
      screen.getByRole("heading", { level: 1, name: /trusted home services/i })
    ).toBeInTheDocument();
    expect(
      screen.getAllByRole("link", { name: /get started/i }).length
    ).toBeGreaterThan(0);
    expect(
      screen.getAllByRole("link", { name: /explore services/i }).length
    ).toBeGreaterThan(0);
  });

  test("renders service categories from the API with view service actions", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      new Response(JSON.stringify(categories), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    );
    render(<HomePage />);

    expect(await screen.findByText("Child Care")).toBeInTheDocument();
    expect(screen.getByText("Elderly Care")).toBeInTheDocument();
    expect(
      screen.getAllByRole("link", { name: /view service/i }).length
    ).toBeGreaterThan(0);
  });

  test("renders why, how it works, story and CTA sections", () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      new Response(JSON.stringify(categories), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    );
    render(<HomePage />);

    expect(
      screen.getByRole("heading", { name: /why homecare platform/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("heading", { name: /how it works/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("heading", { name: /care that fits around your life/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("heading", { name: /need help at home/i })
    ).toBeInTheDocument();
  });

  test("hero and service images reference local assets", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      new Response(JSON.stringify(categories), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    );
    render(<HomePage />);

    const heroImage = screen.getByAltText(
      /a welcoming home cared for by homecare platform/i
    );
    expect(heroImage).toHaveAttribute("src", "/images/hero-home.svg");

    const serviceImage = await screen.findByAltText("Child care");
    expect(serviceImage).toHaveAttribute(
      "src",
      "/images/services/child-care.svg"
    );
  });
});
