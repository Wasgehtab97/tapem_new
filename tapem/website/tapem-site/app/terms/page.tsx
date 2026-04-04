export const metadata = {
  title: "Terms | Tap'em",
  description: "Terms and conditions for the Tap'em website.",
};

export default function TermsPage() {
  return (
    <main className="min-h-screen px-6 py-24" style={{ background: "#0a0a0f", color: "#ededf0" }}>
      <div className="mx-auto max-w-3xl">
        <h1
          className="mb-6"
          style={{ fontFamily: "var(--font-orbitron)", fontSize: "clamp(1.6rem, 4vw, 2.4rem)", fontWeight: 800 }}
        >
          Terms
        </h1>
        <p className="mb-8 text-sm leading-relaxed" style={{ color: "#a6a8ba" }}>
          This page is a launch placeholder and must be replaced with your final contractual terms before onboarding paying customers.
        </p>

        <section className="space-y-4 text-sm leading-relaxed" style={{ color: "#a6a8ba" }}>
          <p>
            Tap&apos;em provides fitness tracking software and related services for gyms and members.
          </p>
          <p>
            Product descriptions on this site are informational and non-binding unless explicitly stated otherwise in a signed agreement.
          </p>
          <p>
            Availability, features, and pricing may change. Formal terms apply only in written contracts between Tap&apos;em and the customer.
          </p>
          <p>
            Liability is limited as permitted by applicable law.
          </p>
          <p>
            Governing law and venue: [insert jurisdiction details].
          </p>
        </section>
      </div>
    </main>
  );
}
