class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}

final onboardingList = [
  OnboardingData(
    image: "assets/images/onboarding/ai_safety.png",
    title: "Meet Your AI Safety Companion",
    description:
    "Smart, proactive, and always by your side. Our AI learns your routines to offer personalized safety alerts and instant support when you need it most.",
  ),
  OnboardingData(
    image: "assets/images/onboarding/sos.png",
    title: "Activate SOS Instantly",
    description:
    "In an emergency, press and hold the SOS button. We'll immediately share your live location with your emergency contacts and authorities.",
  ),
  OnboardingData(
    image: "assets/images/onboarding/pre_alert.png",
    title: "Pre-Alert Mode",
    description:
    "Feel secure on any trip. Set a timer and we’ll check in. If you don’t respond, your emergency contacts are automatically notified.",
  ),
];
