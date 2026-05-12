import 'package:flutter/material.dart';
import 'Onboarding_screen_2.dart';

class OnboardingScreen1 extends StatelessWidget {

  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFD8C2F2),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [

              const SizedBox(height: 40),

              Expanded(
                child: Image.asset(
                  "assets/images/onboarding1.png",
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Tu compañero\ninteligente de salud",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Registra tus niveles de glucosa,\ncomidas y actividades diarias.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnboardingScreen2(),
                    ),
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(22),
                ),

                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}