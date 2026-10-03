import PageHero from "@/components/PageHero";
import SectionHeading from "@/components/SectionHeading";

export default function AboutPage() {
  return (
    <>
      <PageHero
        title="About Homecare Platform"
        lead="A marketplace that connects customers with local service providers for home care and household services."
      />
      <div className="container section">
        <div className="about-grid">
          <div className="about-media">
            <img
              src="/images/lifestyle-care.svg"
              alt="A caregiver and an elderly person sitting together on a bench"
              loading="lazy"
            />
          </div>
          <div className="about-copy">
            <h2>How the platform works</h2>
            <p>
              Customers describe the work they need, and the
              platform matches the request with providers who
              offer the relevant service categories. Providers
              respond with quotes, and customers choose the
              provider that best fits their needs.
            </p>
            <p>
              Every request is tracked through a clear status
              workflow, so customers always know whether their
              service is pending, in progress or completed.
            </p>
          </div>
        </div>
        <SectionHeading
          align="left"
          title="What the platform provides"
          lead="Everything below is part of the platform today."
        />
        <div className="card-grid">
          <div className="card">
            <h3>Service discovery</h3>
            <p>
              Browse published service categories with
              descriptions of the work covered.
            </p>
          </div>
          <div className="card">
            <h3>Transparent quotes</h3>
            <p>
              Providers submit itemized quotes with prices
              that customers approve or reject.
            </p>
          </div>
          <div className="card">
            <h3>Request tracking</h3>
            <p>
              Follow each request from submission through
              assignment to completion.
            </p>
          </div>
          <div className="card">
            <h3>Reviews</h3>
            <p>
              Customers can rate and review providers after
              completed work.
            </p>
          </div>
        </div>
      </div>
    </>
  );
}
