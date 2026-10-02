import 'package:flutter/material.dart';

import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavyBlue,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  size: 64,
                  color: AppColors.darkNavyBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Homecare Platform',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Quality home-care services',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final int pageIndex;
  final int totalPages;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.pageIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                Icon(icon, size: 100, color: AppColors.darkNavyBlue),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepNavyBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.secondaryText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalPages,
                    (index) => Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pageIndex == index
                            ? AppColors.darkNavyBlue
                            : AppColors.borderGrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Find Trusted Care',
      'description':
          'Connect with verified home-care providers who are background-checked and approved for your peace of mind.',
      'icon': Icons.search,
    },
    {
      'title': 'Request & Get Quotes',
      'description':
          'Submit your service request with location details and receive competitive quotes from nearby providers.',
      'icon': Icons.receipt_long,
    },
    {
      'title': 'Track & Pay',
      'description':
          'Track your service in real-time, make secure payments, and leave reviews for completed services.',
      'icon': Icons.payment,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: List.generate(_pages.length, (index) {
          final page = _pages[index];
          return OnboardingPage(
            title: page['title'] as String,
            description: page['description'] as String,
            icon: page['icon'] as IconData,
            pageIndex: index,
            totalPages: _pages.length,
          );
        }),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            TextButton(
              onPressed: () {
                _pageController.jumpToPage(_pages.length - 1);
              },
              child: const Text(
                'Skip',
                style: TextStyle(color: AppColors.secondaryNavyBlue),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  if (_pageController.page!.round() < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                    );
                  } else {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkNavyBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.arrow_forward),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
