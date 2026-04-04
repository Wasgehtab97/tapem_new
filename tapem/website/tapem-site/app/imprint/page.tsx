export const metadata = {
  title: "Imprint | Tap'em",
  description: "Legal notice (Impressum) for Tap'em.",
};

export default function ImprintPage() {
  return (
    <main className="min-h-screen px-6 py-24" style={{ background: "#0a0a0f", color: "#ededf0" }}>
      <div className="mx-auto max-w-3xl">
        <h1
          className="mb-6"
          style={{ fontFamily: "var(--font-orbitron)", fontSize: "clamp(1.6rem, 4vw, 2.4rem)", fontWeight: 800 }}
        >
          Impressum
        </h1>
        <p className="mb-8 text-sm leading-relaxed" style={{ color: "#a6a8ba" }}>
          This page is a launch placeholder and must be replaced with your full legal company details before going public in Germany.
        </p>

        <section className="space-y-4 text-sm leading-relaxed" style={{ color: "#a6a8ba" }}>
          <p>
            Angaben gemaess Paragraph 5 DDG:
          </p>
          <p>
            [Unternehmen/Name]
            <br />
            [Strasse und Hausnummer]
            <br />
            [PLZ Ort]
            <br />
            [Land]
          </p>
          <p>
            Vertreten durch: [Vorname Nachname]
          </p>
          <p>
            Kontakt:
            <br />
            E-Mail: kontakt@tapem.de
            <br />
            Telefon: [Telefonnummer]
          </p>
          <p>
            Umsatzsteuer-ID (falls vorhanden): [USt-IdNr.]
          </p>
          <p>
            Verantwortlich fuer den Inhalt nach Paragraph 18 MStV:
            <br />
            [Vorname Nachname, Anschrift]
          </p>
        </section>
      </div>
    </main>
  );
}
