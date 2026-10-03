export default function PageHero({ title, lead }) {
  return (
    <section className="page-hero">
      <div className="container">
        <h1>{title}</h1>
        {lead && <p>{lead}</p>}
      </div>
    </section>
  );
}
