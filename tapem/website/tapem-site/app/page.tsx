import { Nav } from "@/components/nav";
import { Hero } from "@/components/hero";
import { ProblemBar } from "@/components/problem-bar";
import { HowItWorks } from "@/components/how-it-works";
import { Features } from "@/components/features";
import { XPSystem } from "@/components/xp-system";
import { Community } from "@/components/community";
import { ForGyms } from "@/components/for-gyms";
import { Download } from "@/components/download";
import { Footer } from "@/components/footer";

export default function Home() {
  return (
    <main>
      <Nav />
      <Hero />
      <ProblemBar />
      <HowItWorks />
      <Features />
      <XPSystem />
      <Community />
      <ForGyms />
      <Download />
      <Footer />
    </main>
  );
}
