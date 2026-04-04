import type { Metadata } from "next";
import { Orbitron, Barlow, JetBrains_Mono } from "next/font/google";
import "./globals.css";
import { siteConfig } from "@/lib/site-config";

const orbitron = Orbitron({
  variable: "--font-orbitron",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
  display: "swap",
});

const barlow = Barlow({
  variable: "--font-barlow",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
  display: "swap",
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains",
  subsets: ["latin"],
  weight: ["300", "400", "500"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL(siteConfig.siteUrl),
  title: "Tap'em — Track Your Workout in Seconds",
  description:
    "Tap'em is the NFC-first gym workout tracker that maps your gym's real equipment. Tap. Track. Level up — with your gym community.",
  openGraph: {
    url: siteConfig.siteUrl,
    siteName: siteConfig.siteName,
    title: "Tap'em — Track Your Workout in Seconds",
    description:
      "NFC-first workout tracking. Gym-individualized equipment. Offline-capable. 3 XP axes.",
    type: "website",
  },
  alternates: {
    canonical: "/",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${orbitron.variable} ${barlow.variable} ${jetbrainsMono.variable}`}
    >
      <body className="scanlines antialiased">{children}</body>
    </html>
  );
}
