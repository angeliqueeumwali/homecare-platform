import Link from "next/link";
import { serviceImage } from "@/lib/serviceImages";

export default function ServiceCard({ category }) {
  const image = serviceImage(category);

  return (
    <article className="service-card">
      <Link
        className="service-card-link"
        href={`/services/${category.id}`}
      >
        <div className="service-card-image">
          <img src={image.src} alt={image.alt} loading="lazy" />
        </div>
        <div className="service-card-body">
          <h3>{category.name}</h3>
          <p>
            {category.description ||
              "Home services provided through the platform."}
          </p>
          <span className="service-card-cta">
            View service
            <span className="service-card-arrow" aria-hidden="true">
              &rarr;
            </span>
          </span>
        </div>
      </Link>
    </article>
  );
}
