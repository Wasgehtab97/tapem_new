"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import { siteConfig } from "@/lib/site-config";

export function Download() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section
      id="download"
      ref={ref}
      className="py-28 relative overflow-hidden"
      style={{ borderTop: "1px solid #1e1e30" }}
    >
      {/* Strong ambient glow */}
      <div
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            "radial-gradient(ellipse 70% 60% at 50% 50%, rgba(0,229,255,0.06) 0%, transparent 70%)",
        }}
      />
      <div className="pointer-events-none absolute inset-0 grid-bg opacity-50" />

      <div className="max-w-4xl mx-auto px-6 text-center relative z-10">
        {/* NFC pulse large */}
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={inView ? { opacity: 1, scale: 1 } : {}}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          className="relative inline-flex items-center justify-center mb-10"
          style={{ width: 100, height: 100 }}
        >
          {[0, 1, 2].map((i) => (
            <div
              key={i}
              className="nfc-ring"
              style={{ width: "100%", height: "100%", animationDelay: `${i * 0.8}s` }}
            />
          ))}
          <div
            className="relative z-10 flex items-center justify-center w-16 h-16"
            style={{
              border: "2px solid rgba(0,229,255,0.7)",
              background: "rgba(0,229,255,0.1)",
              borderRadius: "50%",
              boxShadow: "0 0 30px rgba(0,229,255,0.3)",
            }}
          >
            <svg width="28" height="28" viewBox="0 0 32 32" fill="none">
              <path d="M8 16C8 11.58 11.58 8 16 8" stroke="#00e5ff" strokeWidth="2" strokeLinecap="round" />
              <path d="M4 16C4 9.37 9.37 4 16 4" stroke="#00e5ff" strokeWidth="1.5" strokeLinecap="round" strokeOpacity="0.5" />
              <path d="M12 16C12 13.79 13.79 12 16 12" stroke="#00e5ff" strokeWidth="2" strokeLinecap="round" />
              <circle cx="16" cy="16" r="2.5" fill="#00e5ff" />
              <path d="M24 16C24 20.42 20.42 24 16 24" stroke="#00e5ff" strokeWidth="2" strokeLinecap="round" />
              <path d="M28 16C28 22.63 22.63 28 16 28" stroke="#00e5ff" strokeWidth="1.5" strokeLinecap="round" strokeOpacity="0.5" />
              <path d="M20 16C20 18.21 18.21 20 16 20" stroke="#00e5ff" strokeWidth="2" strokeLinecap="round" />
            </svg>
          </div>
        </motion.div>

        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ delay: 0.15, duration: 0.7 }}
          className="mb-6"
          style={{
            fontFamily: "var(--font-orbitron)",
            fontSize: "clamp(1.8rem, 5vw, 3.5rem)",
            fontWeight: 900,
            color: "#ededf0",
            lineHeight: 1.1,
          }}
        >
          Start training smarter
          <br />
          <span className="glow-cyan" style={{ color: "#00e5ff" }}>today.</span>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ delay: 0.25, duration: 0.6 }}
          className="mb-12 text-base leading-relaxed max-w-xl mx-auto"
          style={{ color: "#60637a" }}
        >
          Download Tap&apos;em, get your gym&apos;s join code from the front desk,
          and track your first workout in under 2 minutes.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ delay: 0.35, duration: 0.6 }}
          className="flex flex-wrap gap-4 justify-center mb-16"
        >
          <AppStoreBadge platform="ios" />
          <AppStoreBadge platform="android" />
        </motion.div>

        {/* Fine print */}
        <motion.p
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ delay: 0.5, duration: 0.6 }}
          style={{
            fontFamily: "var(--font-jetbrains)",
            fontSize: "0.65rem",
            color: "#2e2e4a",
            letterSpacing: "0.1em",
          }}
        >
          REQUIRES GYM MEMBERSHIP · OFFLINE-FIRST · EU DATA REGION
        </motion.p>
      </div>
    </section>
  );
}

function AppStoreBadge({ platform }: { platform: "ios" | "android" }) {
  const isIos = platform === "ios";
  const href = isIos ? siteConfig.appStore.ios : siteConfig.appStore.android;
  const isExternalUrl = href.startsWith("http://") || href.startsWith("https://");

  return (
    <a
      href={href}
      target={isExternalUrl ? "_blank" : undefined}
      rel={isExternalUrl ? "noopener noreferrer" : undefined}
      className="flex items-center gap-3 px-5 py-4 transition-all duration-200 group"
      style={{
        border: "1px solid #2e2e4a",
        background: "#12121a",
        clipPath: "polygon(0 0, calc(100% - 10px) 0, 100% 10px, 100% 100%, 0 100%)",
        minWidth: 180,
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.borderColor = "rgba(0,229,255,0.35)";
        e.currentTarget.style.boxShadow = "0 0 20px rgba(0,229,255,0.1)";
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.borderColor = "#2e2e4a";
        e.currentTarget.style.boxShadow = "none";
      }}
    >
      {isIos ? (
        <svg width="22" height="26" viewBox="0 0 22 26" fill="none">
          <path d="M18.25 13.75c-.03-3.32 2.72-4.93 2.84-5-.03-.07-1.53-2.73-3.76-2.73-.45 0-1.9.12-2.83.12-.93 0-2.38-.12-3.31-.12-3.19.04-6.09 2.88-6.09 7.33 0 4.1 2.78 10.16 5.74 10.16 1.12 0 2.28-1.42 3.31-1.42 1.06 0 2.1 1.42 3.31 1.42.47 0 .92-.17 1.31-.47-2.54-1.78-3.53-5.29-.52-9.29z" fill="#ededf0" />
          <path d="M14.6 3.5c.78-1.04 1.3-2.4 1.16-3.5-1.16.05-2.64.78-3.47 1.82-.76.92-1.4 2.32-1.22 3.48 1.28.1 2.58-.65 3.53-1.8z" fill="#ededf0" />
        </svg>
      ) : (
        <svg width="22" height="24" viewBox="0 0 22 24" fill="none">
          <path d="M.5 1.27c0-.73.82-1.14 1.41-.7L21.5 12 1.91 23.43C1.32 23.87.5 23.46.5 22.73V1.27z" fill="#ededf0" opacity="0.9" />
        </svg>
      )}
      <div className="text-left">
        <div style={{ fontFamily: "var(--font-jetbrains)", fontSize: "0.55rem", color: "#60637a", letterSpacing: "0.1em" }}>
          {isIos ? "DOWNLOAD ON THE" : "GET IT ON"}
        </div>
        <div style={{ fontFamily: "var(--font-orbitron)", fontSize: "0.8rem", fontWeight: 700, color: "#ededf0" }}>
          {isIos ? "App Store" : "Google Play"}
        </div>
      </div>
    </a>
  );
}
