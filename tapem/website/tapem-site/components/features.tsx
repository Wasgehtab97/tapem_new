"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";

const features = [
  {
    color: "#00e5ff",
    label: "NFC-First",
    title: "Tap to start in seconds",
    desc: "NFC tags on every machine. Tap your phone, the exercise loads. Manual fallback is always one tap away — identical flow, same speed.",
  },
  {
    color: "#ff00cc",
    label: "Gym-Specific",
    title: "Your gym's real equipment",
    desc: "Tap'em digitizes your gym's actual machine catalog. Fixed machines, open stations, cardio equipment — each tracked as it really is.",
  },
  {
    color: "#ffe600",
    label: "Offline-First",
    title: "Train without a signal",
    desc: "Every set saves locally to your device the moment you log it. No connection needed. Syncs silently when you reconnect.",
  },
  {
    color: "#00e5ff",
    label: "XP System",
    title: "Three axes of progress",
    desc: "Training Day consistency, Equipment Mastery, and Muscle Group depth. Three separate XP tracks — each level earned through real training data.",
  },
  {
    color: "#ff00cc",
    label: "Community",
    title: "Your gym tribe, not the world",
    desc: "Gym-internal friends, privacy-controlled activity feeds, and fair leaderboards. Your community stays inside your gym.",
  },
  {
    color: "#ffe600",
    label: "Training Plans",
    title: "Plans built for your gym",
    desc: "Create and follow plans built around your gym's actual equipment. Coaches can assign and track plans with member progress.",
  },
];

function FeatureIcon({ color }: { color: string }) {
  return (
    <div
      className="w-10 h-10 flex items-center justify-center mb-6 shrink-0"
      style={{
        border: `1px solid ${color}50`,
        background: `${color}10`,
        clipPath: "polygon(0 0, calc(100% - 8px) 0, 100% 8px, 100% 100%, 0 100%)",
      }}
    >
      <div
        className="w-2 h-2 rounded-full"
        style={{ background: color, boxShadow: `0 0 8px ${color}` }}
      />
    </div>
  );
}

export function Features() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  const colorClass: Record<string, string> = {
    "#00e5ff": "hud-card-cyan",
    "#ff00cc": "hud-card-magenta",
    "#ffe600": "hud-card-yellow",
  };

  return (
    <section id="features" ref={ref} className="py-28 relative">
      <div
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            "radial-gradient(ellipse 60% 40% at 20% 50%, rgba(0,229,255,0.03) 0%, transparent 70%)",
        }}
      />
      <div className="max-w-7xl mx-auto px-6">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="mb-16"
        >
          <span className="section-label mb-4 block">Features</span>
          <h2
            style={{
              fontFamily: "var(--font-orbitron)",
              fontSize: "clamp(1.5rem, 4vw, 2.5rem)",
              fontWeight: 800,
              color: "#ededf0",
              lineHeight: 1.15,
            }}
          >
            Built for the gym floor.
            <br />
            <span style={{ color: "#60637a" }}>Every feature earns its place.</span>
          </h2>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-px" style={{ background: "#1e1e30" }}>
          {features.map((f, i) => (
            <motion.div
              key={f.title}
              initial={{ opacity: 0, y: 24 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: i * 0.08, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
              className={`hud-card ${colorClass[f.color]} p-8`}
              style={{ clipPath: "none", borderRadius: 0, border: "none" }}
            >
              <FeatureIcon color={f.color} />

              <div
                className="mb-2 text-xs tracking-widest uppercase"
                style={{
                  fontFamily: "var(--font-jetbrains)",
                  color: f.color,
                  opacity: 0.7,
                }}
              >
                {f.label}
              </div>
              <h3
                className="mb-3 text-base font-semibold"
                style={{ fontFamily: "var(--font-orbitron)", color: "#ededf0", letterSpacing: "0.03em" }}
              >
                {f.title}
              </h3>
              <p className="text-sm leading-relaxed" style={{ color: "#60637a" }}>
                {f.desc}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
