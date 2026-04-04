"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import { siteConfig } from "@/lib/site-config";

const stats = [
  { value: "< 10s", label: "Workout start time", sub: "NFC or manual — identical experience" },
  { value: "3", label: "XP axes", sub: "Consistency · Equipment · Muscle Group" },
  { value: "100%", label: "Offline-capable", sub: "Core workout flow never requires a signal" },
];

const benefits = [
  {
    title: "Your gym, digitized",
    desc: "Tap'em maps your actual equipment — machine names, types, exercises. Your members train in an app that knows your floor.",
  },
  {
    title: "Real engagement data",
    desc: "See which machines members use, training frequency per member, and community activity. Trainers work with real load data.",
  },
  {
    title: "Member retention",
    desc: "Visible progress, fair rankings, and a gym-internal community give your members reasons to keep showing up — and tracking.",
  },
  {
    title: "Simple onboarding",
    desc: "Members join via a Gym Code. You distribute it — a poster, QR code, or message. That's it. No complex admin setup.",
  },
];

export function ForGyms() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section
      id="for-gyms"
      ref={ref}
      className="py-28 relative overflow-hidden"
      style={{ borderTop: "1px solid #1e1e30" }}
    >
      {/* Grid bg */}
      <div className="pointer-events-none absolute inset-0 grid-bg opacity-40" />

      {/* Ambient */}
      <div
        className="pointer-events-none absolute"
        style={{
          right: "-5%",
          top: "20%",
          width: 500,
          height: 500,
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(0,229,255,0.04) 0%, transparent 70%)",
        }}
      />

      <div className="max-w-7xl mx-auto px-6">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="mb-16 max-w-2xl"
        >
          <span className="section-label mb-4 block">For Gym Owners</span>
          <h2
            className="mb-6"
            style={{
              fontFamily: "var(--font-orbitron)",
              fontSize: "clamp(1.5rem, 4vw, 2.5rem)",
              fontWeight: 800,
              color: "#ededf0",
              lineHeight: 1.15,
            }}
          >
            Your gym becomes
            <br />
            <span className="glow-cyan" style={{ color: "#00e5ff" }}>
              a digital training platform.
            </span>
          </h2>
          <p className="text-base leading-relaxed" style={{ color: "#60637a" }}>
            Tap&apos;em is a B2B2C product. The gym partners with Tap&apos;em. Members get the app.
            Your equipment gets digitized. Engagement becomes measurable.
          </p>
        </motion.div>

        {/* Stats row */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-px mb-16" style={{ background: "#1e1e30" }}>
          {stats.map((s, i) => (
            <motion.div
              key={s.label}
              initial={{ opacity: 0, y: 20 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: i * 0.1, duration: 0.6 }}
              className="px-8 py-10 text-center"
              style={{ background: "#0a0a0f" }}
            >
              <div
                className="mb-2 glow-cyan"
                style={{
                  fontFamily: "var(--font-orbitron)",
                  fontSize: "clamp(2rem, 5vw, 3.5rem)",
                  fontWeight: 900,
                  color: "#00e5ff",
                  lineHeight: 1,
                }}
              >
                {s.value}
              </div>
              <div
                className="mb-1 text-sm font-semibold"
                style={{ color: "#ededf0" }}
              >
                {s.label}
              </div>
              <div
                className="text-xs"
                style={{ fontFamily: "var(--font-jetbrains)", color: "#2e2e4a" }}
              >
                {s.sub}
              </div>
            </motion.div>
          ))}
        </div>

        {/* Benefits grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {benefits.map((b, i) => (
            <motion.div
              key={b.title}
              initial={{ opacity: 0, y: 20 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: 0.2 + i * 0.1, duration: 0.6 }}
              className="flex gap-5"
            >
              <div
                className="mt-1 shrink-0 w-2 h-2 rounded-full"
                style={{ background: "#00e5ff", boxShadow: "0 0 8px #00e5ff" }}
              />
              <div>
                <h3
                  className="mb-2 text-base font-semibold"
                  style={{ fontFamily: "var(--font-orbitron)", color: "#ededf0", letterSpacing: "0.03em" }}
                >
                  {b.title}
                </h3>
                <p className="text-sm leading-relaxed" style={{ color: "#60637a" }}>
                  {b.desc}
                </p>
              </div>
            </motion.div>
          ))}
        </div>

        {/* CTA */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ delay: 0.5, duration: 0.6 }}
          className="mt-16 p-8 flex flex-col sm:flex-row gap-6 items-start sm:items-center justify-between"
          style={{
            border: "1px solid rgba(0,229,255,0.25)",
            background: "linear-gradient(135deg, rgba(0,229,255,0.06) 0%, #12121a 60%)",
            clipPath: "polygon(0 0, calc(100% - 20px) 0, 100% 20px, 100% 100%, 0 100%)",
          }}
        >
          <div>
            <h3
              className="mb-2 text-xl font-bold"
              style={{ fontFamily: "var(--font-orbitron)", color: "#ededf0" }}
            >
              Bring Tap&apos;em to your gym
            </h3>
            <p className="text-sm" style={{ color: "#60637a" }}>
              Contact us to get your gym on the platform. We handle the equipment setup.
            </p>
          </div>
          <a
            href={`mailto:${siteConfig.contactEmail}`}
            className="btn-primary shrink-0"
          >
            Get in touch
          </a>
        </motion.div>
      </div>
    </section>
  );
}
