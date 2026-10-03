export default function SettingsPage() {
  const unavailable = [
    {
      label: "Platform configuration",
      reason:
        "The backend does not expose platform settings endpoints yet.",
    },
    {
      label: "Email delivery configuration",
      reason:
        "Email delivery is not configured on the backend. Password reset and contact notifications are stored and processed without sending email.",
    },
    {
      label: "Payment provider credentials",
      reason:
        "Payments are recorded through the existing payment workflow only. No payment provider settings are managed here.",
    },
  ];

  return (
    <div>
      <div className="card-header">
        <h2>Settings</h2>
      </div>
      <div className="card">
        <p className="state-text" style={{ margin: 0 }}>
          Settings are limited to features supported by the
          backend. The following areas are currently unavailable:
        </p>
      </div>
      {unavailable.map((item) => (
        <div className="card" key={item.label}>
          <h3 className="section-title" style={{ marginTop: 0 }}>
            {item.label}
          </h3>
          <p className="state-text" style={{ margin: 0 }}>
            {item.reason}
          </p>
          <span className="badge badge-warning">Unavailable</span>
        </div>
      ))}
    </div>
  );
}
