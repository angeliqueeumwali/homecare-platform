import Hero from "@/components/home/Hero";
import ServicesSection from "@/components/home/ServicesSection";
import WhySection from "@/components/home/WhySection";
import HowItWorksSection from "@/components/home/HowItWorksSection";
import StorySection from "@/components/home/StorySection";
import CTASection from "@/components/home/CTASection";

export default function HomePage() {
  return (
    <>
      <Hero />
      <ServicesSection />
      <WhySection />
      <HowItWorksSection />
      <StorySection />
      <CTASection />
    </>
  );
}
