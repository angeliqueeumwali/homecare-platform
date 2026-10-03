import Link from "next/link";
import PageHero from "@/components/PageHero";

const STEPS = [
  {
    icon: "/images/steps/step-explore.svg",
    title: "Create an account",
    body: "Register with your name, email address and phone number. Your account is created with the customer role, which lets you request services.",
  },
  {
    icon: "/images/steps/step-request.svg",
    title: "Submit a service request",
    body: "Choose a service category, describe the work, and provide your address and preferred date. Each request can include multiple service items.",
  },
  {
    icon: "/images/steps/step-match.svg",
    title: "Providers are matched",
    body: "The platform matches your request with providers who offer the requested categories and are available in your area.",
  },
  {
    icon: "/images/steps/step-quotes.svg",
    title: "Review quotes",
    body: "Matched providers submit quotes with a price and description. You can approve or reject each quote.",
  },
  {
    icon: "/images/steps/step-track.svg",
    title: "Assignment and progress",
    body: "Approving a quote assigns the provider to your request. The request moves through pending, in progress and completed statuses, which you can follow in your account.",
  },
  {
    icon: "/images/steps/step-review.svg",
    title: "Payment and review",
    body: "When the work is done, the payment is recorded through the platform. You can rate and review the provider to help other customers.",
  },
];

export default function HowItWorksPage() {
  return (
    <>
      <PageHero
        title="How it works"
        lead="From finding a service to reviewing your provider, here is the full customer journey on the Homecare Platform."
      />
      <div className="container section">
        <ol className="step-cards step-cards-3col">
          {STEPS.map((step, index) => (
            <li className="step-card" key={step.title}>
              <span className="step-badge" aria-hidden="true">
                {index + 1}
              </span>
              <img
                className="step-icon"
                src={step.icon}
                alt=""
                loading="lazy"
              />
              <h3>{step.title}</h3>
              <p>{step.body}</p>
            </li>
          ))}
        </ol>
        <div
          className="card"
          style={{
            marginTop: "3rem",
            textAlign: "center",
            padding: "2.5rem",
          }}
        >
          <h3>Ready to get started?</h3>
          <p className="state-text" style={{ margin: "0 auto 1.4rem" }}>
            Create an account to request your first
            service.
          </p>
          <Link className="btn btn-primary btn-lg" href="/register">
            Register
          </Link>
        </div>
      </div>
    </>
  );
}
