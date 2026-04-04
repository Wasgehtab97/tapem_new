export const metadata = {
  title: "Privacy Policy | Tap'em",
  description: "Privacy information for the Tap'em website.",
};

export default function PrivacyPage() {
  return (
    <main className="min-h-screen px-6 py-24" style={{ background: "#0a0a0f", color: "#ededf0" }}>
      <div className="mx-auto max-w-3xl">
        <h1
          className="mb-6"
          style={{ fontFamily: "var(--font-orbitron)", fontSize: "clamp(1.6rem, 4vw, 2.4rem)", fontWeight: 800 }}
        >
          Privacy Policy
        </h1>
        <p className="mb-8 text-sm leading-relaxed" style={{ color: "#a6a8ba" }}>
          This page is a launch placeholder and must be replaced with your final legal text before running paid marketing campaigns.
        </p>

        <section className="space-y-4 text-sm leading-relaxed" style={{ color: "#a6a8ba" }}>
          <p>
            Controller: [Full legal entity name], [address], [email], [phone]
          </p>
          <p>
            Data we process on this website: server logs, contact requests, and technical metadata required for security and delivery.
          </p>
          <p>
            Legal basis: Art. 6(1)(b), Art. 6(1)(f) GDPR. If consent-based tools are used later, Art. 6(1)(a) GDPR applies.
          </p>
          <p>
            Recipients: hosting provider and technical processors necessary to run this website.
          </p>
          <p>
            Retention periods: logs and inquiries are retained only as long as operationally or legally required.
          </p>
          <p>
            Your rights: access, rectification, deletion, restriction, objection, portability, and complaint to your supervisory authority.
          </p>
        </section>
      </div>
    </main>
  );
}
