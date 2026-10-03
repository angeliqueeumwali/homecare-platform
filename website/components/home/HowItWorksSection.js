import Link from "next/link";
import SectionHeading from "@/components/SectionHeading";

const STEPS = [
  {
    icon: "/images/steps/step-explore.svg",
    title: "Explore a service",
    body: "Browse published service categories and read what each one covers.",
  },
  {
    icon: "/images/steps/step-request.svg",
    title: "Request the service",
    body: "Create an account, describe the work, and add your address and preferred date.",
  },
  {
    icon: "/images/steps/step-quotes.svg",
    title: "Receive and manage quotes",
    body: "Matched providers submit quotes with a price and description for you to review.",
  },
  {
    icon: "/images/steps/step-track.svg",
    title: "Follow it to completion",
    body: "Approve a quote to assign a provider and track the request until the work is done.",
  },
];

export default function HowItWorksSection() {
  return (
    <section className="section section-alt">
      <div className="container">
        <SectionHeading
          title="How it works"
          lead="From exploring a service to a completed job, every step happens on the platform."
        />
        <ol className="step-cards">
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
        <div className="section-more" style={{ textAlign: "center" }}>
          <Link className="btn btn-outline btn-lg" href="/how-it-works">
            See the full process
          </Link>
        </div>
      </div>
    </section>
  );
}
