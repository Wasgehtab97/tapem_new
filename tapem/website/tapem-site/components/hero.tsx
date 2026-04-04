"use client";

import { motion } from "framer-motion";
import { ArrowRight, ChevronDown } from "lucide-react";

const ease = [0.16, 1, 0.3, 1] as [number, number, number, number];

function fadeUpProps(i: number) {
  return {
    initial: { opacity: 0, y: 24 },
    animate: { opacity: 1, y: 0 },
    transition: { delay: i * 0.12, duration: 0.65, ease },
  };
}

export function Hero() {
  return (
    <section
      className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden grid-bg"
      style={{ paddingTop: "4rem" }}
    >
      {/* Radial ambient */}
      <div
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            "radial-gradient(ellipse 70% 50% at 50% 20%, rgba(0,229,255,0.07) 0%, transparent 70%), radial-gradient(ellipse 50% 40% at 80% 80%, rgba(255,0,204,0.05) 0%, transparent 60%)",
        }}
      />

      <div className="relative z-10 max-w-6xl mx-auto px-6 flex flex-col items-center text-center">
        {/* Badge */}
        <motion.div
          {...fadeUpProps(0)}
          className="mb-8"
        >
          <span
            className="inline-flex items-center gap-2 px-4 py-2 text-xs tracking-widest uppercase"
            style={{
              fontFamily: "var(--font-jetbrains)",
              color: "#00e5ff",
              border: "1px solid rgba(0,229,255,0.3)",
              background: "rgba(0,229,255,0.06)",
              clipPath: "polygon(0 0, calc(100% - 8px) 0, 100% 8px, 100% 100%, 0 100%)",
            }}
          >
            <span
              className="w-1.5 h-1.5 rounded-full"
              style={{ background: "#00e5ff", boxShadow: "0 0 6px #00e5ff" }}
            />
            NFC-First · Offline-Capable · Available Now
          </span>
        </motion.div>

        {/* Headline */}
        <motion.h1
          {...fadeUpProps(1)}
          className="glitch mb-6"
          style={{
            fontFamily: "var(--font-orbitron)",
            fontWeight: 900,
            fontSize: "clamp(2.4rem, 8vw, 6rem)",
            lineHeight: 1.0,
            letterSpacing: "-0.01em",
            color: "#ededf0",
          }}
        >
          Track your workout
          <br />
          <span className="glow-cyan" style={{ color: "#00e5ff" }}>
            in seconds.
          </span>
        </motion.h1>

        {/* Subline */}
        <motion.p
          {...fadeUpProps(2)}
          className="max-w-2xl mb-10"
          style={{
            fontSize: "1.15rem",
            lineHeight: 1.7,
            color: "#60637a",
            fontWeight: 400,
          }}
        >
          Tap the NFC tag on any machine. Your gym&apos;s real equipment — mapped. Your sets,
          reps, and progress — tracked. No setup, no friction.
          <br />
          <span style={{ color: "#ededf0" }}>Just train.</span>
        </motion.p>

        {/* CTAs */}
        <motion.div
          {...fadeUpProps(3)}
          className="flex flex-wrap gap-4 justify-center mb-16"
        >
          <a href="#download" className="btn-primary">
            Download App
            <ArrowRight size={14} />
          </a>
          <a href="#for-gyms" className="btn-secondary">
            For Gym Owners
            <ArrowRight size={14} />
          </a>
        </motion.div>

        {/* NFC Visual */}
        <motion.div
          {...fadeUpProps(4)}
          className="relative"
          style={{ width: "min(560px, 90vw)" }}
        >
          <NFCPhoneVisual />
        </motion.div>
      </div>

      {/* Scroll hint */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 2, duration: 0.8 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
        style={{ color: "#2e2e4a" }}
      >
        <ChevronDown size={18} className="animate-bounce" />
      </motion.div>
    </section>
  );
}

function NFCPhoneVisual() {
  return (
    <div className="relative flex items-center justify-center" style={{ height: 340 }}>
      {/* NFC pulse rings */}
      <div className="absolute" style={{ width: 140, height: 140, top: "50%", left: "50%", transform: "translate(-50%,-50%)" }}>
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            className="nfc-ring"
            style={{
              width: "100%",
              height: "100%",
              animationDelay: `${i * 0.8}s`,
            }}
          />
        ))}
      </div>

      {/* Center NFC icon */}
      <div
        className="relative z-10 flex items-center justify-center"
        style={{
          width: 80,
          height: 80,
          border: "2px solid rgba(0,229,255,0.6)",
          background: "rgba(0,229,255,0.08)",
          borderRadius: "50%",
          boxShadow: "0 0 30px rgba(0,229,255,0.25), inset 0 0 20px rgba(0,229,255,0.05)",
        }}
      >
        <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
          <path d="M8 16C8 11.58 11.58 8 16 8" stroke="#00e5ff" strokeWidth="2" strokeLinecap="round" />
          <path d="M4 16C4 9.37 9.37 4 16 4" stroke="#00e5ff" strokeWidth="1.5" strokeLinecap="round" strokeOpacity="0.5" />
          <path d="M12 16C12 13.79 13.79 12 16 12" stroke="#00e5ff" strokeWidth="2" strokeLinecap="round" />
          <circle cx="16" cy="16" r="2.5" fill="#00e5ff" />
          <path d="M24 16C24 20.42 20.42 24 16 24" stroke="#00e5ff" strokeWidth="2" strokeLinecap="round" />
          <path d="M28 16C28 22.63 22.63 28 16 28" stroke="#00e5ff" strokeWidth="1.5" strokeLinecap="round" strokeOpacity="0.5" />
          <path d="M20 16C20 18.21 18.21 20 16 20" stroke="#00e5ff" strokeWidth="2" strokeLinecap="round" />
        </svg>
      </div>

      {/* Floating data cards */}
      <FloatingCard
        style={{ top: 30, right: -20 }}
        label="Bench Press"
        value="85 kg × 8"
        color="#00e5ff"
        delay={1.2}
      />
      <FloatingCard
        style={{ bottom: 40, left: -10 }}
        label="XP Earned"
        value="+25 XP"
        color="#ffe600"
        delay={1.6}
      />
      <FloatingCard
        style={{ top: 110, left: -30 }}
        label="Sync Status"
        value="● Live"
        color="#00e5ff"
        delay={2.0}
        small
      />
    </div>
  );
}

function FloatingCard({
  style,
  label,
  value,
  color,
  delay,
  small = false,
}: {
  style: React.CSSProperties;
  label: string;
  value: string;
  color: string;
  delay: number;
  small?: boolean;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ delay, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
      className="absolute"
      style={{
        ...style,
        background: "rgba(18,18,26,0.95)",
        border: `1px solid ${color}33`,
        backdropFilter: "blur(8px)",
        padding: small ? "6px 12px" : "10px 16px",
        clipPath: "polygon(0 0, calc(100% - 8px) 0, 100% 8px, 100% 100%, 0 100%)",
      }}
    >
      <div
        style={{
          fontFamily: "var(--font-jetbrains)",
          fontSize: "0.55rem",
          color: "#60637a",
          letterSpacing: "0.15em",
          textTransform: "uppercase",
          marginBottom: 2,
        }}
      >
        {label}
      </div>
      <div
        style={{
          fontFamily: "var(--font-jetbrains)",
          fontSize: small ? "0.7rem" : "0.9rem",
          color,
          fontWeight: 500,
        }}
      >
        {value}
      </div>
    </motion.div>
  );
}
