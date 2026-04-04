"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";

const members = [
  { name: "marcus_k", level: 9, streak: 42, status: "Training now", color: "#00e5ff" },
  { name: "julia.fit", level: 7, streak: 31, status: "Trained today", color: "#ff00cc" },
  { name: "tomvolkov", level: 12, streak: 67, status: "Rank #1 Equipment", color: "#ffe600" },
  { name: "sarah.d", level: 5, streak: 18, status: "Trained 2d ago", color: "#00e5ff" },
];

const leaderboardRows = [
  { rank: 1, name: "tomvolkov", xp: "67,200 XP", level: 12, color: "#ffe600" },
  { rank: 2, name: "marcus_k", xp: "42,100 XP", level: 9, color: "#60637a" },
  { rank: 3, name: "julia.fit", xp: "31,400 XP", level: 7, color: "#60637a" },
  { rank: 4, name: "you", xp: "14,200 XP", level: 4, color: "#00e5ff", highlight: true },
];

export function Community() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section
      ref={ref}
      className="py-28 relative overflow-hidden"
      style={{ borderTop: "1px solid #1e1e30" }}
    >
      <div
        className="pointer-events-none absolute"
        style={{
          left: "-5%",
          top: "10%",
          width: 500,
          height: 500,
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(255,0,204,0.04) 0%, transparent 70%)",
        }}
      />

      <div className="max-w-7xl mx-auto px-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          {/* Left: community UI mockup */}
          <motion.div
            initial={{ opacity: 0, x: -24 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="space-y-3"
          >
            {/* Leaderboard card */}
            <div
              className="p-5"
              style={{
                border: "1px solid #1e1e30",
                background: "#12121a",
                clipPath: "polygon(0 0, calc(100% - 14px) 0, 100% 14px, 100% 100%, 0 100%)",
              }}
            >
              <div className="flex items-center gap-2 mb-4">
                <span
                  style={{
                    fontFamily: "var(--font-jetbrains)",
                    fontSize: "0.6rem",
                    letterSpacing: "0.22em",
                    textTransform: "uppercase",
                    color: "#ffe600",
                    opacity: 0.8,
                  }}
                >
                  Consistency Ranking
                </span>
                <div className="flex-1 h-px" style={{ background: "rgba(255,230,0,0.15)" }} />
                <span style={{ fontFamily: "var(--font-jetbrains)", fontSize: "0.6rem", color: "#2e2e4a" }}>
                  LIFTHOUSE GYM
                </span>
              </div>
              <div className="space-y-2">
                {leaderboardRows.map((row, i) => (
                  <motion.div
                    key={row.name}
                    initial={{ opacity: 0, x: -12 }}
                    animate={inView ? { opacity: 1, x: 0 } : {}}
                    transition={{ delay: 0.3 + i * 0.08, duration: 0.5 }}
                    className="flex items-center gap-3 px-3 py-2"
                    style={{
                      background: row.highlight ? "rgba(0,229,255,0.06)" : "transparent",
                      border: row.highlight ? "1px solid rgba(0,229,255,0.2)" : "1px solid transparent",
                    }}
                  >
                    <span
                      style={{
                        fontFamily: "var(--font-jetbrains)",
                        fontSize: "0.7rem",
                        color: row.rank === 1 ? "#ffe600" : "#2e2e4a",
                        width: 20,
                      }}
                    >
                      #{row.rank}
                    </span>
                    <span
                      style={{
                        fontFamily: "var(--font-jetbrains)",
                        fontSize: "0.75rem",
                        color: row.highlight ? "#00e5ff" : "#ededf0",
                        flex: 1,
                      }}
                    >
                      {row.name}
                    </span>
                    <span style={{ fontFamily: "var(--font-jetbrains)", fontSize: "0.65rem", color: "#60637a" }}>
                      LVL {row.level}
                    </span>
                    <span style={{ fontFamily: "var(--font-jetbrains)", fontSize: "0.65rem", color: row.color }}>
                      {row.xp}
                    </span>
                  </motion.div>
                ))}
              </div>
            </div>

            {/* Friends strip */}
            <div
              className="p-5"
              style={{
                border: "1px solid #1e1e30",
                background: "#12121a",
                clipPath: "polygon(0 0, calc(100% - 14px) 0, 100% 14px, 100% 100%, 0 100%)",
              }}
            >
              <div className="flex items-center gap-2 mb-4">
                <span
                  style={{
                    fontFamily: "var(--font-jetbrains)",
                    fontSize: "0.6rem",
                    letterSpacing: "0.22em",
                    textTransform: "uppercase",
                    color: "#ff00cc",
                    opacity: 0.8,
                  }}
                >
                  Gym Friends
                </span>
                <div className="flex-1 h-px" style={{ background: "rgba(255,0,204,0.15)" }} />
              </div>
              <div className="grid grid-cols-2 gap-2">
                {members.map((m, i) => (
                  <motion.div
                    key={m.name}
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={inView ? { opacity: 1, scale: 1 } : {}}
                    transition={{ delay: 0.5 + i * 0.07, duration: 0.4 }}
                    className="p-3"
                    style={{ border: "1px solid #1e1e30", background: "#1c1c2e" }}
                  >
                    <div className="flex items-center gap-2 mb-1">
                      <div
                        className="w-1.5 h-1.5 rounded-full shrink-0"
                        style={{
                          background: m.status === "Training now" ? "#00e5ff" : "#2e2e4a",
                          boxShadow: m.status === "Training now" ? "0 0 6px #00e5ff" : "none",
                        }}
                      />
                      <span style={{ fontFamily: "var(--font-jetbrains)", fontSize: "0.65rem", color: "#ededf0" }}>
                        {m.name}
                      </span>
                    </div>
                    <div style={{ fontFamily: "var(--font-jetbrains)", fontSize: "0.55rem", color: "#60637a" }}>
                      LVL {m.level} · {m.status}
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>
          </motion.div>

          {/* Right: copy */}
          <motion.div
            initial={{ opacity: 0, x: 24 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.7, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
          >
            <span className="section-label mb-4 block">Community</span>
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
              Your gym.
              <br />
              <span className="glow-magenta" style={{ color: "#ff00cc" }}>
                Your people.
              </span>
            </h2>
            <p className="mb-6 text-base leading-relaxed" style={{ color: "#60637a" }}>
              Community in Tap&apos;em is gym-internal by design. Leaderboards, friends, and activity
              are all scoped to your gym — not a global feed you don&apos;t control.
            </p>
            <div className="space-y-4">
              {[
                ["Rankings are fair", "Only validated, server-processed XP appears on leaderboards. No exploits, no manipulation."],
                ["Privacy is yours", "Three privacy levels. You decide what your gym friends can see of your training."],
                ["Three leaderboards", "Training Consistency, Equipment Mastery, Muscle Group. Compete where you dominate."],
              ].map(([title, desc]) => (
                <div key={title} className="flex gap-4">
                  <div
                    className="mt-1.5 w-1.5 h-1.5 rounded-full shrink-0"
                    style={{ background: "#ff00cc", boxShadow: "0 0 6px #ff00cc" }}
                  />
                  <div>
                    <div className="text-sm font-semibold mb-1" style={{ color: "#ededf0" }}>{title}</div>
                    <div className="text-sm leading-relaxed" style={{ color: "#60637a" }}>{desc}</div>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
