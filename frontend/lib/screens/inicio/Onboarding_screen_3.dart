import 'package:flutter/material.dart';

class OnboardingScreen3 extends StatelessWidget {

  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFFF7448),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [

              const SizedBox(height: 40),

              Expanded(
                child: Image.asset(
                  "assets/images/onboarding3.png",
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Comienza tu\ncamino saludable",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "GlucoWatch te ayudará a mantener\nun mejor control de tu diabetes.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {

                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(22),
                ),

                child: const Icon(
                  Icons.check,
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