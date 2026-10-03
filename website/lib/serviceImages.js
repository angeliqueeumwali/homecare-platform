const SERVICE_IMAGES = [
  {
    keys: ["child"],
    src: "/images/services/child-care.svg",
    alt: "Child care",
  },
  {
    keys: ["elderly"],
    src: "/images/services/elderly-care.svg",
    alt: "Elderly care",
  },
  {
    keys: ["companionship"],
    src: "/images/services/companionship.svg",
    alt: "Companionship",
  },
  {
    keys: ["cooking", "meal"],
    src: "/images/services/cooking.svg",
    alt: "Cooking and meal preparation",
  },
  {
    keys: ["garden", "lawn"],
    src: "/images/services/gardening.svg",
    alt: "Gardening and lawn care",
  },
  {
    keys: ["housekeeping", "cleaning"],
    src: "/images/services/housekeeping.svg",
    alt: "General housekeeping",
  },
  {
    keys: ["repair", "maintenance"],
    src: "/images/services/repairs.svg",
    alt: "Home repairs and maintenance",
  },
  {
    keys: ["laundry"],
    src: "/images/services/laundry.svg",
    alt: "Laundry services",
  },
  {
    keys: ["medical", "nursing"],
    src: "/images/services/nursing.svg",
    alt: "Medical and nursing",
  },
  {
    keys: ["pet"],
    src: "/images/services/pet-care.svg",
    alt: "Pet care",
  },
];

const FALLBACK = {
  src: "/images/services/housekeeping.svg",
  alt: "Home service",
};

export function serviceImage(category) {
  const name = (category?.name || "").toLowerCase();
  const match = SERVICE_IMAGES.find((entry) =>
    entry.keys.some((key) => name.includes(key))
  );
  return match || FALLBACK;
}
