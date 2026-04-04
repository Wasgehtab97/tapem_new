"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef } from "react";

const problems = [
  {
    icon: "⌛",
    svgPath: "M12 2v10l4 2M20 12a8 8 0 1 1-16 0 8 8 0 0 1 16 0Z",
    title: "Minutes to start",
    desc: "Most apps force you through menus before you can log a single set.",
    fix: "Tap'em starts in under 10 seconds. Tap the NFC tag on the machine — done.",
  },
  {
    svgPath: "M9 12h6m-3-3v6M3 12a9 9 0 1 1 18 0 9 9 0 0 1-18 0Z",
    title: "Generic equipment",
    desc: "Apps don't know your gym's actual machines, layouts, or equipment labels.",
    fix: "Every gym gets its own digitized equipment catalog. Your machines, your exercises.",
  },
  {
    svgPath: "M17 20h5v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2h5m5-10a4 4 0 1 1 0-8 4 4 0 0 1 0 8Z",
    title: "No gym community",
    desc: "Training is better with your gym tribe — but standard apps only show global feeds.",
    fix: "Gym-internal friends, rankings, and activity. Only your gym. Private by design.",
  },
];

export function ProblemBar() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section
      ref={ref}
      className="py-20 relative"
      style={{ borderTop: "1px solid #1e1e30", borderBottom: "1px solid #1e1e30" }}
    >
      <div
        className="pointer-events-none absolute inset-0"
        style={{
          background: "linear-gradient(180deg, rgba(0,229,255,0.015) 0%, transparent 50%)",
        }}
      />
      <div className="max-w-7xl mx-auto px-6">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
          className="text-center mb-14"
        >
          <span className="section-label mb-4 block">The problem</span>
          <h2
            style={{
              fontFamily: "var(--font-orbitron)",
              fontSize: "clamp(1.5rem, 4vw, 2.5rem)",
              fontWeight: 800,
              color: "#ededf0",
              lineHeight: 1.15,
            }}
          >
            Standard fitness apps weren&apos;t built
            <br />
            <span style={{ color: "#60637a" }}>for the gym floor.</span>
          </h2>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-px" style={{ background: "#1e1e30" }}>
          {problems.map((p, i) => (
            <motion.div
              key={p.title}
              initial={{ opacity: 0, y: 20 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: i * 0.1, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
              className="relative p-8"
              style={{ background: "#0a0a0f" }}
            >
              {/* Problem */}
              <div className="mb-6">
                <div
                  className="mb-3 text-xs tracking-widest uppercase"
                  style={{ fontFamily: "var(--font-jetbrains)", color: "#2e2e4a" }}
                >
                  Problem_{String(i + 1).padStart(2, "0")}
                </div>
                <h3
                  className="mb-3 text-base font-semibold"
                  style={{ color: "#ededf0" }}
                >
                  {p.title}
                </h3>
                <p className="text-sm leading-relaxed" style={{ color: "#60637a" }}>
                  {p.desc}
                </p>
              </div>

              {/* Divider */}
              <div
                className="w-full mb-6"
                style={{
                  height: 1,
                  background: "linear-gradient(90deg, rgba(0,229,255,0.3), transparent)",
                }}
              />

              {/* Fix */}
              <div>
                <div
                  className="mb-2 text-xs tracking-widest uppercase"
                  style={{ fontFamily: "var(--font-jetbrains)", color: "#00e5ff", opacity: 0.7 }}
                >
                  Tap&apos;em fix
                </div>
                <p className="text-sm leading-relaxed" style={{ color: "#ededf0" }}>
                  {p.fix}
                </p>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
