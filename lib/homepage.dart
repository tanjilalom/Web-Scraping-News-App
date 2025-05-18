import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_scraping_with_flutter/features/pages/bajus_prices_screen.dart';
import 'package:web_scraping_with_flutter/features/pages/banglanews24_news_screen.dart';
import 'package:web_scraping_with_flutter/features/pages/ittefaq_news_screen.dart';
import 'package:web_scraping_with_flutter/features/pages/kalerkontho_news_screen.dart';
import 'package:web_scraping_with_flutter/features/pages/prothomalo_news_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD), // Lighter, modern background
      appBar: AppBar(
        title: Text(
          'News Portals',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3366FF),
        // Modern blue gradient start
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3366FF),
                Color(0xFF00CCFF),
              ],
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore News Sources',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPortalCard(
                    context,
                    title: 'Bajus Gold & Silver Price',
                    icon: Icons.monetization_on_outlined,
                    color: const Color(0xFFFF9F43),
                    onTap: () => _navigateWithFade(context, const BajusRateScreen()),
                  ),
                  const SizedBox(height: 16),
                  _buildPortalCard(
                    context,
                    title: 'Kaler Kontho News',
                    icon: Icons.newspaper_outlined,
                    color: const Color(0xFF28C76F),
                    onTap: () => _navigateWithFade(
                        context, const KalerKonthoNewsScreen()),
                  ),
                  const SizedBox(height: 16),
                  _buildPortalCard(
                    context,
                    title: 'Prothom Alo News',
                    icon: Icons.newspaper_outlined,
                    color: const Color(0xFF28C76F),
                    onTap: () =>
                        _navigateWithFade(context, const ProthomAloNewsScreen()),
                  ),
                  const SizedBox(height: 16),
                  _buildPortalCard(
                    context,
                    title: 'Banglanews24 News',
                    icon: Icons.newspaper_outlined,
                    color: const Color(0xFF28C76F),
                    onTap: () =>
                        _navigateWithFade(context, const BanglaNews24Screen()),
                  ),
                  _buildPortalCard(
                    context,
                    title: 'Ittefaq News',
                    icon: Icons.newspaper_outlined,
                    color: const Color(0xFF28C76F),
                    onTap: () =>
                        _navigateWithFade(context, const IttefaqNewsScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateWithFade(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildPortalCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: color,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
