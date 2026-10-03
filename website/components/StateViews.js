export function LoadingState({ label = "Loading..." }) {
  return (
    <div className="page-state" role="status" aria-live="polite">
      <div className="spinner" aria-hidden="true" />
      <p className="state-text">{label}</p>
    </div>
  );
}

export function EmptyState({
  title = "No results found",
  message = "Please check back later.",
}) {
  return (
    <div className="page-state">
      <p className="state-title">{title}</p>
      <p className="state-text">{message}</p>
    </div>
  );
}

export function ErrorState({ message, onRetry }) {
  return (
    <div className="page-state" role="alert">
      <p className="state-title" style={{ color: "var(--error)" }}>
        Something went wrong
      </p>
      <p className="state-text">{message}</p>
      {onRetry && (
        <button
          type="button"
          className="btn btn-primary"
          onClick={onRetry}
        >
          Try again
        </button>
      )}
    </div>
  );
}
