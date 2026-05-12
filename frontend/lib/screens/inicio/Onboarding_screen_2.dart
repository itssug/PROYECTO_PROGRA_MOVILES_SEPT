import 'package:flutter/material.dart';
import 'Onboarding_screen_3.dart';

class OnboardingScreen2 extends StatelessWidget {

  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF49D18A),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [

              const SizedBox(height: 40),

              Expanded(
                child: Image.asset(
                  "assets/images/onboarding2.png",
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Controla todo\nlo importante",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Mide glucosa, registra agua,\nalimentación y actividad física.",
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
                      builder: (_) => const OnboardingScreen3(),
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