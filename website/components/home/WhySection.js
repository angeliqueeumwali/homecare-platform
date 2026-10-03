import SectionHeading from "@/components/SectionHeading";

const FEATURES = [
  {
    icon: "/images/features/icon-convenient.svg",
    title: "Convenient home services",
    body: "Describe the work you need once, with your address and preferred date, and let matched providers come to you.",
  },
  {
    icon: "/images/features/icon-local.svg",
    title: "Local service providers",
    body: "The platform matches your request with providers who offer the service categories you need.",
  },
  {
    icon: "/images/features/icon-process.svg",
    title: "A simple request process",
    body: "Create a request with a category, description, address and preferred date, and add several service items at once.",
  },
  {
    icon: "/images/features/icon-track.svg",
    title: "Track every request",
    body: "Follow your request through pending, in progress and completed, then rate and review your provider.",
  },
];

export default function WhySection() {
  return (
    <section className="section">
      <div className="container">
        <SectionHeading
          title="Why Homecare Platform?"
          lead="One place to describe the work, compare quotes from matched providers, and follow the job through to completion."
        />
        <div className="feature-grid">
          {FEATURES.map((feature) => (
            <div className="feature-card" key={feature.title}>
              <img
                className="feature-icon"
                src={feature.icon}
                alt=""
                loading="lazy"
              />
              <h3>{feature.title}</h3>
              <p>{feature.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
