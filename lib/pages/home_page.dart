import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';
import 'trial_chat_page.dart';
import 'backend/login_page.dart';

class TrialChatPage extends StatefulWidget {
  const TrialChatPage({super.key});

  @override
  State<TrialChatPage> createState() => _TrialChatPageState();
}

class _TrialChatPageState extends State<TrialChatPage> with TickerProviderStateMixin {
  // Feature tile widget
  Widget _FeatureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color glowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.18),
            blurRadius: 12,
            spreadRadius: 1.5,
          ),
        ],
        border: Border.all(color: glowColor.withOpacity(0.55), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: color.withOpacity(0.18),
              radius: 18,
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedBackground(
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                baseColor: Colors.white.withOpacity(0.8),
                spawnMinSpeed: 10.0,
                spawnMaxSpeed: 40.0,
                spawnMinRadius: 1.0,
                spawnMaxRadius: 2.0,
                particleCount: 40,
                image: null,
              ),
            ),
            vsync: this,
            child: Container(),
          ),
          SafeArea(
            child: Column(
              children: [
                // Add extra space at the top
                const SizedBox(height: 60),
                
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 👆 Circle with Image
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(0.18),
                            radius: 40,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // Spacing between pic and text

                        // 👇 Quike AI Text
                        Text(
                          'Quike AI',
                          style: TextStyle(
                            fontSize: 38,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.blueAccent.withOpacity(0.4),
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Feature tiles
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.9,
                                  child: _FeatureTile(
                                    icon: Icons.flash_on,
                                    color: Colors.yellowAccent,
                                    title: 'Lightning fast responses',
                                    subtitle: 'Powered by ZaAn LLC',
                                    glowColor: Colors.yellowAccent,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.9,
                                  child: _FeatureTile(
                                    icon: Icons.person_outline,
                                    color: Colors.greenAccent,
                                    title: 'Personality-driven chat',
                                    subtitle: 'Created by BlackCarbon Team',
                                    glowColor: Colors.greenAccent,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.9,
                                  child: _FeatureTile(
                                    icon: Icons.code,
                                    color: Colors.purpleAccent,
                                    title: 'Code Generation',
                                    subtitle: 'Get code snippets and solutions',
                                    glowColor: Colors.purpleAccent,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.9,
                                  child: _FeatureTile(
                                    icon: Icons.format_bold,
                                    color: Colors.orangeAccent,
                                    title: 'Text Formatting',
                                    subtitle: 'Bold text and code highlighting',
                                    glowColor: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Bottom padding
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom action buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withOpacity(0.85),
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text(
                        'Try Quike',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
