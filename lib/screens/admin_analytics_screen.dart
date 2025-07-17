import 'package:flutter/material.dart';
import '../themes/admin_theme.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AdminTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('📊 Thống kê & Phân tích', style: AdminTheme.displayMedium),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text('Analytics Dashboard', style: AdminTheme.headlineLarge),
                      const SizedBox(height: 8),
                      Text('Coming soon...', style: AdminTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}