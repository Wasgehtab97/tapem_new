"use client";

import { motion, useInView, animate } from "framer-motion";
import { useRef, useEffect, useState } from "react";

const axes = [
  {
    id: "consistency",
    label: "Training Consistency",
    code: "training_day",
    color: "#00e5ff",
    colorDim: "rgba(0,229,255,0.12)",
    level: 7,
    xp: 14200,
    maxXp: 15000,
    desc: "Awarded for every valid training day — once per day, regardless of volume. Rewards showing up.",
    icon: "◈",
  },
  {
    id: "equipment",
    label: "Equipment Mastery",
    code: "exercise_equipment",
    color: "#ff00cc",
    colorDim: "rgba(255,0,204,0.12)",
    level: 4,
    xp: 3840,
    maxXp: 5000,
    desc: "Earned per set across your exercises. More variety, deeper mastery. 5 XP per set, capped per session.",
    icon: "◆",
  },
  {
    id: "muscle",
    label: "Muscle Group Depth",
    code: "muscle_group",
    color: "#ffe600",
    colorDim: "rgba(255,230,0,0.12)",
    level: 2,
    xp: 1200,
    maxXp: 2000,
    desc: "Mapped to primary and secondary muscle groups per exercise. Rewards a balanced, structured approach.",
    icon: "◉",
  },
];

function AnimatedCounter({ target, color }: { target: number; color: string }) {
  const [display, setDisplay] = useState(0);
  const ref = useRef(null);
  const inView = useInView(ref, { once: true });

  useEffect(() => {
    if (!inView) return;
    const controls = animate(0, target, {
      duration: 1.8,
      ease: "easeOut",
      onUpdate: (v) => setDisplay(Math.round(v)),
    });
    return controls.stop;
  }, [inView, target]);

  return (
    <span ref={ref} style={{ color, fontFamily: "var(--font-jetbrains)" }}>
      {display.toLocaleString("en-US")}
    </span>
  );
}

function XPBar({ xp, maxXp, color, inView }: { xp: number; maxXp: number; color: string; inView: boolean }) {
  const pct = Math.round((xp / maxXp) * 100);
  return (
    <div
      className="w-full h-2 rounded-none relative overflow-hidden"
      style={{ background: "rgba(255,255,255,0.06)" }}
    >
      <motion.div
        className="h-full absolute top-0 left-0"
        initial={{ width: 0 }}
        animate={inView ? { width: `${pct}%` } : { width: 0 }}
        transition={{ duration: 1.4, ease: [0.16, 1, 0.3, 1], delay: 0.3 }}
        style={{
          background: `linear-gradient(90deg, ${color}80, ${color})`,
          boxShadow: `0 0 10px ${color}80`,
        }}
      />
    </div>
  );
}

export function XPSystem() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="xp-system" ref={ref} className="py-28 relative" style={{ borderTop: "1px solid #1e1e30" }}>
      <div
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            "radial-gradient(ellipse 70% 60% at 50% 100%, rgba(0,229,255,0.04) 0%, transparent 70%)",
        }}
      />
      <div className="max-w-7xl mx-auto px-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-start">
          {/* Left: copy */}
          <motion.div
            initial={{ opacity: 0, x: -24 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          >
            <span className="section-label mb-4 block">XP System</span>
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
              Three tracks.
              <br />
              <span className="glow-cyan" style={{ color: "#00e5ff" }}>
                All earned.
              </span>
            </h2>
            <p className="mb-8 text-base leading-relaxed" style={{ color: "#60637a" }}>
              XP is never gamified for the sake of it. Every point comes from real training data —
              server-validated, idempotent, manipulation-resistant.
            </p>
            <p className="text-sm leading-relaxed mb-10" style={{ color: "#60637a" }}>
              Level up across three independent axes: showing up consistently, mastering your
              equipment, and building muscle group depth. Each axis has its own leaderboard in
              your gym.
            </p>

            {/* XP formula note */}
            <div
              className="p-4"
              style={{
                fontFamily: "var(--font-jetbrains)",
                fontSize: "0.7rem",
                color: "#60637a",
                border: "1px solid #1e1e30",
                background: "#12121a",
                lineHeight: 1.8,
              }}
            >
              <div style={{ color: "#00e5ff", marginBottom: 6, opacity: 0.7 }}>
                {"// XP rules"}
              </div>
              <div>training_day → 25 XP / day (once per gym)</div>
              <div>exercise_set → 5 XP + ⌊reps÷5⌋ (max 120 / session)</div>
              <div>muscle_group → primary: 10 XP · secondary: 2.5 XP</div>
              <div>level_threshold → 100 XP = 1 level</div>
            </div>
          </motion.div>

          {/* Right: axes */}
          <div className="flex flex-col gap-6">
            {axes.map((ax, i) => (
              <motion.div
                key={ax.id}
                initial={{ opacity: 0, x: 24 }}
                animate={inView ? { opacity: 1, x: 0 } : {}}
                transition={{ delay: i * 0.15, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
                className="p-6"
                style={{
                  border: `1px solid ${ax.color}25`,
                  background: `linear-gradient(135deg, ${ax.colorDim} 0%, #12121a 60%)`,
                  clipPath: "polygon(0 0, calc(100% - 12px) 0, 100% 12px, 100% 100%, 0 100%)",
                }}
              >
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <div
                      className="text-xs tracking-widest uppercase mb-1"
                      style={{ fontFamily: "var(--font-jetbrains)", color: ax.color, opacity: 0.75 }}
                    >
                      {ax.code}
                    </div>
                    <h3 style={{ fontFamily: "var(--font-orbitron)", fontSize: "0.9rem", fontWeight: 700, color: "#ededf0" }}>
                      {ax.label}
                    </h3>
                  </div>
                  <div
                    className="flex items-center justify-center text-sm font-bold px-3 py-1"
                    style={{
                      fontFamily: "var(--font-jetbrains)",
                      color: ax.color,
                      border: `1px solid ${ax.color}50`,
                      background: `${ax.color}12`,
                    }}
                  >
                    LVL {ax.level}
                  </div>
                </div>

                <p className="text-xs mb-4 leading-relaxed" style={{ color: "#60637a" }}>
                  {ax.desc}
                </p>

                <div className="mb-2">
                  <XPBar xp={ax.xp} maxXp={ax.maxXp} color={ax.color} inView={inView} />
                </div>

                <div className="flex justify-between text-xs" style={{ fontFamily: "var(--font-jetbrains)", color: "#2e2e4a" }}>
                  <span>
                    <AnimatedCounter target={ax.xp} color={ax.color} /> XP
                  </span>
                  <span>{ax.maxXp.toLocaleString("en-US")} XP → LVL {ax.level + 1}</span>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
