export default function AboutPage() {
  return (
    <div className="container section">
      <h1>About Homecare Platform</h1>
      <div className="card" style={{ marginTop: "1rem" }}>
        <p>
          Homecare Platform is a marketplace that connects
          customers with local service providers for home
          care and household services.
        </p>
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
      <h2 className="section-title">What the platform provides</h2>
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
  );
}
