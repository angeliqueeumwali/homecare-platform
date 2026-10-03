import Link from "next/link";

export default function StorySection() {
  return (
    <section className="section">
      <div className="container story-grid">
        <div className="story-media">
          <img
            src="/images/lifestyle-care.svg"
            alt="A caregiver and an elderly person sitting together on a bench"
            loading="lazy"
          />
        </div>
        <div className="story-copy">
          <h2>Care that fits around your life</h2>
          <p>
            Homecare Platform brings care and household
            services into one simple request. Whether you
            need help with daily routines, companionship or
            household tasks, the process is the same:
            describe the work, review quotes, and choose the
            provider that fits.
          </p>
          <ul className="story-points">
            <li>
              One request can include several service items
              at once
            </li>
            <li>
              Providers respond with itemized quotes you
              approve or reject
            </li>
            <li>
              Every request shows a clear status, so you
              always know what is happening
            </li>
          </ul>
          <Link className="btn btn-primary btn-lg" href="/how-it-works">
            How it works
          </Link>
        </div>
      </div>
    </section>
  );
}
