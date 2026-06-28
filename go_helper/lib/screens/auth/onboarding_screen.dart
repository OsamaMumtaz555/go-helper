import 'package:flutter/material.dart';
import 'package:go_helper/utils/Constants/colors.dart';
import 'package:go_helper/utils/Constants/text_strings.dart';
import 'package:go_helper/utils/constants/image_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': HImages.onBoardingImage1,
      'title': HTexts.onBoardingTitle1,
      'subtitle': HTexts.onBoardingSubTitle1,
    },
    {
      'image': HImages.onBoardingImage2,
      'title': HTexts.onBoardingTitle2,
      'subtitle': HTexts.onBoardingSubTitle2,
    },
    {
      'image': HImages.onBoardingImage3,
      'title': HTexts.onBoardingTitle3,
      'subtitle': HTexts.onBoardingSubTitle3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final logoSize = screenWidth * 0.15;
    final imageHeight = screenHeight * 0.35;
    final titleFontSize = screenWidth * 0.07;
    final subtitleFontSize = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            children: [
              // ========== TOP BAR ==========
              _buildTopBar(logoSize),
              SizedBox(height: screenHeight * 0.03),

              // ========== MAIN CONTENT ==========
              Expanded(
                child: _buildPageView(
                  imageHeight,
                  titleFontSize,
                  subtitleFontSize,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // ========== BOTTOM BAR ==========
              _buildBottomBar(screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Bar Widget - Skip button on ALL pages
  Widget _buildTopBar(double logoSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo
        Image.asset(
          HImages.appLogo,
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),

        //  Skip Button - ALWAYS VISIBLE on ALL pages
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Row(
            children: [
              const Text(
                HTexts.skip,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: HColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                HImages.skipIcon,
                width: 20,
                height: 20,
                color: HColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Page View Widget
  Widget _buildPageView(
    double imageHeight,
    double titleFontSize,
    double subtitleFontSize,
  ) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: _pages.length,
      itemBuilder:
          (context, index) => _buildPage(
            _pages[index],
            imageHeight,
            titleFontSize,
            subtitleFontSize,
          ),
    );
  }

  // 3. Single Page Widget
  Widget _buildPage(
    Map<String, String> page,
    double imageHeight,
    double titleFontSize,
    double subtitleFontSize,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image
        Container(
          constraints: BoxConstraints(
            maxHeight: imageHeight,
            maxWidth: double.infinity,
          ),
          child: Center(
            child: Image.asset(
              page['image']!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: imageHeight,
                  width: double.infinity,
                  color: HColors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.image,
                    size: imageHeight * 0.5,
                    color: HColors.primary,
                  ),
                );
              },
            ),
          ),
        ),

        SizedBox(height: imageHeight * 0.05),

        // Title
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: imageHeight * 0.02),
          child: Text(
            page['title']!,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: titleFontSize.clamp(24, 32),
              fontWeight: FontWeight.w700,
              color: HColors.primary,
              height: 1.3,
            ),
          ),
        ),

        // Subtitle
        SizedBox(
          width: double.infinity,
          child: Text(
            page['subtitle']!,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: subtitleFontSize.clamp(14, 18),
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // 4. Bottom Bar Widget
  Widget _buildBottomBar(double screenWidth) {
    final dotSize = screenWidth * 0.02;
    final activeDotSize = dotSize * 3;

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.05),
      child: Row(
        children: [
          // Pagination Dots
          Row(
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: EdgeInsets.only(right: dotSize * 1.5),
                child: Image.asset(
                  _currentPage == index
                      ? HImages.dotActive
                      : HImages.dotInactive,
                  width: _currentPage == index ? activeDotSize : dotSize,
                  height: dotSize,
                ),
              ),
            ),
          ),

          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
