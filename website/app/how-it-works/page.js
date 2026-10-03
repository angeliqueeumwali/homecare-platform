import Link from "next/link";

const STEPS = [
  {
    title: "Create an account",
    body: "Register with your name, email address and phone number. Your account is created with the customer role, which lets you request services.",
  },
  {
    title: "Submit a service request",
    body: "Choose a service category, describe the work, and provide your address and preferred date. Each request can include multiple service items.",
  },
  {
    title: "Providers are matched",
    body: "The platform matches your request with providers who offer the requested categories and are available in your area.",
  },
  {
    title: "Review quotes",
    body: "Matched providers submit quotes with a price and description. You can approve or reject each quote.",
  },
  {
    title: "Assignment and progress",
    body: "Approving a quote assigns the provider to your request. The request moves through pending, in progress and completed statuses, which you can follow in your account.",
  },
  {
    title: "Payment and review",
    body: "When the work is done, the payment is recorded through the platform. You can rate and review the provider to help other customers.",
  },
];

export default function HowItWorksPage() {
  return (
    <div className="container section">
      <h1>How it works</h1>
      <p>
        From finding a service to reviewing your provider,
        here is the full customer journey on the Homecare
        Platform.
      </p>
      <ol className="steps" style={{ marginTop: "2rem" }}>
        {STEPS.map((step, index) => (
          <li className="step" key={step.title}>
            <div className="step-number">{index + 1}</div>
            <h3>{step.title}</h3>
            <p>{step.body}</p>
          </li>
        ))}
      </ol>
      <div
        className="card"
        style={{ marginTop: "2rem", textAlign: "center" }}
      >
        <h3>Ready to get started?</h3>
        <p className="state-text" style={{ margin: "0 auto 1rem" }}>
          Create a free account to request your first
          service.
        </p>
        <Link className="btn btn-primary" href="/register">
          Register
        </Link>
      </div>
    </div>
  );
}
