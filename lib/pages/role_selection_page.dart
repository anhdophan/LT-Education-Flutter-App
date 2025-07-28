import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import './Students/loginpage.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/header_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xAA000000), Color(0x00FFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: Colors.white.withOpacity(0.92),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hero(
                          tag: 'logo',
                          child: Image.asset('assets/lt_logo.png', height: 80),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'HỆ THỐNG HỌC TRỰC TUYẾN',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'LEARNING MANAGEMENT SYSTEM\nL&T EDUCATION',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: AppColors.gray),
                        ),
                        const SizedBox(height: 28),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Chọn vai trò đăng nhập:',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Button: Student
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.school),
                          label: const Text('Học viên'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Button: Teacher
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to teacher login
                          },
                          icon: const Icon(Icons.person),
                          label: const Text('Giáo viên'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lightGray,
                            foregroundColor: AppColors.textDark,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),
                        const Divider(),
                        const Text(
                          'Ngôn ngữ: Vietnamese (vi)',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
