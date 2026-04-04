import { siteConfig } from "@/lib/site-config";

export const metadata = {
  title: "Contact | Tap'em",
  description: "Contact Tap'em for gym onboarding and product information.",
};

export default function ContactPage() {
  return (
    <main className="min-h-screen px-6 py-24" style={{ background: "#0a0a0f", color: "#ededf0" }}>
      <div className="mx-auto max-w-3xl">
        <h1
          className="mb-6"
          style={{ fontFamily: "var(--font-orbitron)", fontSize: "clamp(1.6rem, 4vw, 2.4rem)", fontWeight: 800 }}
        >
          Contact
        </h1>
        <p className="mb-8 text-sm leading-relaxed" style={{ color: "#a6a8ba" }}>
          If you run a gym and want to onboard Tap&apos;em, send us an email. We will reply with rollout details, timeline, and pricing.
        </p>
        <a
          href={`mailto:${siteConfig.contactEmail}`}
          className="inline-flex items-center px-4 py-3"
          style={{
            border: "1px solid rgba(0,229,255,0.4)",
            color: "#00e5ff",
            fontFamily: "var(--font-jetbrains)",
            letterSpacing: "0.04em",
          }}
        >
          {siteConfig.contactEmail}
        </a>
      </div>
    </main>
  );
}
