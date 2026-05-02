import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';
import 'login_page.dart';
import 'register_page.dart';

class AuthScreen extends StatefulWidget {final int initialTab; 
  const AuthScreen({super.key, this.initialTab = 0});   // 0 = Login, 1 = Register

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
        length: 2, vsync: this, 
        initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.medical_services_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),

              const Text(
                'Selamat Datang!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),

              _buildTabBar(),
              const SizedBox(height: 28),

              SizedBox(
                height: 540,
                child: TabBarView(
                  controller: _tab,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    LoginTab(tabController: _tab),
                    RegisterTab(tabController: _tab),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.inputBorder.withOpacity(0.35),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            const TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 15),
        unselectedLabelStyle:
            const TextStyle(
              fontWeight: FontWeight.w500, 
              fontSize: 15),
        tabs: const [
          Tab(text: 'Login'), 
          Tab(text: 'Register')
        ],
      ),
    );
  }

  Widget _footerLink(String text) => Text(
        text,
        style: 
          const TextStyle(
            fontSize: 11, 
            color: AppColors.textSecondary
          ),
        );

  Widget _dot() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text('·',
            style:
                TextStyle(
                  fontSize: 11, 
                  color: AppColors.textSecondary
                )
        ),
      );
}