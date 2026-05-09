import 'package:flutter/material.dart';
import 'Onboarding_screen_1.dart';

class PrincipalScreen extends StatelessWidget {

  const PrincipalScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [

              const Spacer(),

              RichText(
                text: const TextSpan(
                  children: [

                    TextSpan(
                      text: "Gluco",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    TextSpan(
                      text: "Watch",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Controla tu glucosa\nfácil y rápido",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                ),
              ),

              const Spacer(),

              Image.asset(
                "assets/images/splash.png",
                height: 260,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 60,

                child: ElevatedButton(

                  onPressed: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const OnboardingScreen1(),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: const Text(
                    "Comenzar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}