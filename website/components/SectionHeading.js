export default function SectionHeading({
  title,
  lead,
  align = "center",
}) {
  return (
    <div
      className={`section-heading section-heading-${align}`}
    >
      <h2>{title}</h2>
      {lead && <p>{lead}</p>}
    </div>
  );
}
