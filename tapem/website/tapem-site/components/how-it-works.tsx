"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";

const steps = [
  {
    num: "01",
    color: "#00e5ff",
    title: "Tap the NFC tag",
    desc: "Every machine in your gym has an NFC tag. Tap your phone — the equipment is recognized instantly. No searching, no typing, no friction.",
    detail: "No NFC? Manual start is equally fast — same flow, same result.",
  },
  {
    num: "02",
    color: "#ff00cc",
    title: "Track your sets",
    desc: "Log reps, weight, and notes directly at the machine. Sets save locally in real-time — no sync required. Even offline, every set is safe.",
    detail: "Open stations and cardio supported. Create custom exercises in seconds.",
  },
  {
    num: "03",
    color: "#ffe600",
    title: "Level up",
    desc: "Finish your session and watch XP arrive across three axes: Training Consistency, Equipment Mastery, and Muscle Group. Your effort, measurably rewarded.",
    detail: "Progress syncs when connectivity returns. Nothing is ever lost.",
  },
];

export function HowItWorks() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="how-it-works" ref={ref} className="py-28 relative overflow-hidden">
      {/* Ambient */}
      <div
        className="pointer-events-none absolute"
        style={{
          top: "20%",
          right: "-10%",
          width: 400,
          height: 400,
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(255,0,204,0.05) 0%, transparent 70%)",
        }}
      />
      <div className="max-w-7xl mx-auto px-6">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="mb-16"
        >
          <span className="section-label mb-4 block">How it works</span>
          <h2
            style={{
              fontFamily: "var(--font-orbitron)",
              fontSize: "clamp(1.5rem, 4vw, 2.5rem)",
              fontWeight: 800,
              color: "#ededf0",
              lineHeight: 1.15,
            }}
          >
            Three steps.
            <br />
            <span className="glow-cyan" style={{ color: "#00e5ff" }}>
              Zero friction.
            </span>
          </h2>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-px relative" style={{ background: "transparent" }}>
          {/* Connecting line (desktop) */}
          <div
            className="hidden lg:block absolute top-12 left-0 right-0 pointer-events-none"
            style={{
              height: 1,
              background: "linear-gradient(90deg, transparent 5%, #1e1e30 20%, #1e1e30 80%, transparent 95%)",
            }}
          />

          {steps.map((step, i) => (
            <motion.div
              key={step.num}
              initial={{ opacity: 0, y: 30 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: i * 0.15, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
              className="relative px-8 py-10"
              style={{
                borderLeft: i > 0 ? "1px solid #1e1e30" : "none",
              }}
            >
              {/* Step number */}
              <div className="relative flex items-center gap-4 mb-8">
                <div
                  className="relative z-10 flex items-center justify-center w-10 h-10 shrink-0"
                  style={{
                    border: `2px solid ${step.color}`,
                    background: `${step.color}12`,
                    boxShadow: `0 0 20px ${step.color}40`,
                    clipPath: "polygon(0 0, calc(100% - 6px) 0, 100% 6px, 100% 100%, 0 100%)",
                  }}
                >
                  <span
                    style={{
                      fontFamily: "var(--font-orbitron)",
                      fontSize: "0.65rem",
                      fontWeight: 700,
                      color: step.color,
                    }}
                  >
                    {step.num}
                  </span>
                </div>
                <div
                  className="flex-1"
                  style={{ height: 1, background: `linear-gradient(90deg, ${step.color}30, transparent)` }}
                />
              </div>

              {/* Content */}
              <h3
                className="mb-4 text-xl font-bold"
                style={{
                  fontFamily: "var(--font-orbitron)",
                  color: "#ededf0",
                  fontSize: "1.1rem",
                  letterSpacing: "0.03em",
                }}
              >
                {step.title}
              </h3>
              <p className="mb-6 text-sm leading-relaxed" style={{ color: "#60637a" }}>
                {step.desc}
              </p>

              {/* Detail note */}
              <div
                className="text-xs leading-relaxed px-3 py-2"
                style={{
                  fontFamily: "var(--font-jetbrains)",
                  color: step.color,
                  opacity: 0.7,
                  border: `1px solid ${step.color}20`,
                  background: `${step.color}08`,
                }}
              >
                ↳ {step.detail}
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
