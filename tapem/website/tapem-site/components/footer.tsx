"use client";

export function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer
      className="py-12 relative"
      style={{ borderTop: "1px solid #1e1e30" }}
    >
      <div className="max-w-7xl mx-auto px-6">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-8">
          {/* Logo + tagline */}
          <div>
            <div
              className="text-sm font-bold tracking-widest uppercase mb-2"
              style={{ fontFamily: "var(--font-orbitron)", color: "#ededf0" }}
            >
              Tap&apos;em
            </div>
            <div
              style={{
                fontFamily: "var(--font-jetbrains)",
                fontSize: "0.65rem",
                color: "#2e2e4a",
                letterSpacing: "0.1em",
              }}
            >
              NFC-FIRST GYM WORKOUT TRACKER
            </div>
          </div>

          {/* Links */}
          <nav className="flex flex-wrap gap-6">
            {[
              ["Features", "#features"],
              ["How it works", "#how-it-works"],
              ["XP System", "#xp-system"],
              ["For Gyms", "#for-gyms"],
              ["Privacy", "/privacy"],
              ["Terms", "/terms"],
              ["Imprint", "/imprint"],
              ["Contact", "/contact"],
            ].map(([label, href]) => (
              <a
                key={label}
                href={href}
                className="text-xs transition-colors duration-150"
                style={{ fontFamily: "var(--font-jetbrains)", color: "#2e2e4a", letterSpacing: "0.1em" }}
                onMouseEnter={(e) => (e.currentTarget.style.color = "#60637a")}
                onMouseLeave={(e) => (e.currentTarget.style.color = "#2e2e4a")}
              >
                {label}
              </a>
            ))}
          </nav>

          {/* Copyright */}
          <div
            style={{
              fontFamily: "var(--font-jetbrains)",
              fontSize: "0.65rem",
              color: "#2e2e4a",
              letterSpacing: "0.08em",
            }}
          >
            © {year} Tap&apos;em
          </div>
        </div>

        {/* Bottom rule */}
        <div
          className="mt-8 pt-6"
          style={{ borderTop: "1px solid #1e1e30" }}
        >
          <div
            className="text-center"
            style={{
              fontFamily: "var(--font-jetbrains)",
              fontSize: "0.6rem",
              color: "#1e1e30",
              letterSpacing: "0.15em",
            }}
          >
            EU DATA REGION · OFFLINE-CAPABLE · SUPABASE + FLUTTER
          </div>
        </div>
      </div>
    </footer>
  );
}
