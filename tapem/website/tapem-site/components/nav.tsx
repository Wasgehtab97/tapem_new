"use client";

import { useEffect, useState } from "react";
import { Menu, X } from "lucide-react";
import Link from "next/link";

const links = [
  { label: "Features", href: "#features" },
  { label: "How it works", href: "#how-it-works" },
  { label: "XP System", href: "#xp-system" },
  { label: "For Gyms", href: "#for-gyms" },
];

export function Nav() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className="fixed top-0 left-0 right-0 z-50 transition-all duration-300"
      style={{
        background: scrolled
          ? "rgba(10,10,15,0.92)"
          : "transparent",
        backdropFilter: scrolled ? "blur(16px)" : "none",
        borderBottom: scrolled ? "1px solid #1e1e30" : "1px solid transparent",
      }}
    >
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-3 group">
          <div className="relative w-8 h-8">
            <div
              className="absolute inset-0 rounded-sm"
              style={{
                background: "rgba(0,229,255,0.15)",
                border: "1px solid rgba(0,229,255,0.5)",
                clipPath: "polygon(0 0, calc(100% - 6px) 0, 100% 6px, 100% 100%, 0 100%)",
              }}
            />
            <div
              className="absolute inset-0 flex items-center justify-center"
              style={{ fontFamily: "var(--font-orbitron)", fontSize: "0.65rem", color: "#00e5ff", fontWeight: 700 }}
            >
              T
            </div>
          </div>
          <span
            className="text-sm font-bold tracking-widest uppercase"
            style={{ fontFamily: "var(--font-orbitron)", color: "#ededf0" }}
          >
            Tap&apos;em
          </span>
        </Link>

        {/* Desktop nav */}
        <nav className="hidden md:flex items-center gap-8">
          {links.map((l) => (
            <a
              key={l.href}
              href={l.href}
              className="text-xs tracking-widest uppercase transition-colors duration-150"
              style={{
                fontFamily: "var(--font-jetbrains)",
                color: "#60637a",
              }}
              onMouseEnter={(e) => (e.currentTarget.style.color = "#00e5ff")}
              onMouseLeave={(e) => (e.currentTarget.style.color = "#60637a")}
            >
              {l.label}
            </a>
          ))}
        </nav>

        {/* CTA */}
        <div className="hidden md:flex items-center gap-3">
          <a href="#download" className="btn-primary" style={{ padding: "0.6rem 1.25rem", fontSize: "0.65rem" }}>
            Get the App
          </a>
        </div>

        {/* Mobile menu */}
        <button
          className="md:hidden p-2"
          style={{ color: "#ededf0" }}
          onClick={() => setOpen(!open)}
          aria-label="Toggle menu"
        >
          {open ? <X size={20} /> : <Menu size={20} />}
        </button>
      </div>

      {/* Mobile drawer */}
      {open && (
        <div
          className="md:hidden px-6 pb-6 flex flex-col gap-4"
          style={{
            background: "rgba(10,10,15,0.97)",
            borderTop: "1px solid #1e1e30",
          }}
        >
          {links.map((l) => (
            <a
              key={l.href}
              href={l.href}
              onClick={() => setOpen(false)}
              className="text-xs tracking-widest uppercase py-2"
              style={{ fontFamily: "var(--font-jetbrains)", color: "#60637a" }}
            >
              {l.label}
            </a>
          ))}
          <a href="#download" className="btn-primary mt-2" style={{ justifyContent: "center" }}>
            Get the App
          </a>
        </div>
      )}
    </header>
  );
}
