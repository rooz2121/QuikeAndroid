import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('About Quike AI', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App Logo and Version
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // App Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 60,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App Name
                  const Text(
                    'Quike AI',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // App Version
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // About Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('About'),
                  _buildCard(
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Quike AI is an advanced AI assistant designed to help you with a wide range of tasks. '
                        'Powered by state-of-the-art language models, Quike AI can answer questions, provide information, '
                        'assist with creative writing, and engage in meaningful conversations.\n\n'
                        'Our mission is to make AI technology accessible and helpful for everyone, '
                        'providing a seamless and intuitive interface for interacting with artificial intelligence.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Features
                  _buildSectionTitle('Key Features'),
                  _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureItem(
                            context: context,
                            icon: Icons.chat_bubble_outline,
                            title: 'Intelligent Conversations',
                            description: 'Engage in natural conversations with our advanced AI model.',
                          ),
                          const Divider(),
                          _buildFeatureItem(
                            context: context,
                            icon: Icons.lightbulb_outline,
                            title: 'Smart Recommendations',
                            description: 'Get personalized recommendations based on your preferences',
                          ),
                          const Divider(),
                          _buildFeatureItem(
                            context: context,
                            icon: Icons.code,
                            title: 'Code Generation',
                            description: 'Generate code snippets and solutions for programming tasks',
                          ),
                          const Divider(),
                          _buildFeatureItem(
                            context: context,
                            icon: Icons.dark_mode,
                            title: 'Dark Mode',
                            description: 'Comfortable viewing experience in low-light conditions',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Technology
                  _buildSectionTitle('Technology'),
                  _buildCard(
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Quike AI is built using Flutter for the frontend and Supabase for backend services. '
                        'The AI functionality is powered by Groq, utilizing state-of-the-art language models '
                        'to provide intelligent and contextually relevant responses.\n\n'
                        'We continuously improve our models and user experience based on feedback and '
                        'the latest advancements in AI technology.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Team
                  _buildSectionTitle('Our Team'),
                  _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTeamMember(
                            name: 'Quike Development Team',
                            role: 'Developers & Designers',
                            description: 'A passionate team of developers, designers, and AI specialists dedicated to creating innovative AI solutions.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Contact
                  _buildSectionTitle('Contact Us'),
                  _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.email, color: Colors.blueAccent),
                            title: const Text('Email', style: TextStyle(color: Colors.white)),
                            subtitle: const Text('support@quikeai.com', style: TextStyle(color: Colors.grey)),
                            onTap: () => _launchUrl('mailto:support@quikeai.com'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                          ),
                          const Divider(color: Colors.grey),
                          ListTile(
                            leading: Icon(Icons.language, color: Colors.blueAccent),
                            title: const Text('Website', style: TextStyle(color: Colors.white)),
                            subtitle: const Text('www.quikeai.com', style: TextStyle(color: Colors.grey)),
                            onTap: () => _launchUrl('https://www.quikeai.com'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                          ),
                          const Divider(color: Colors.grey),
                          ListTile(
                            leading: Icon(Icons.bug_report, color: Colors.blueAccent),
                            title: const Text('Report an Issue', style: TextStyle(color: Colors.white)),
                            subtitle: const Text('Let us know if you encounter any problems', style: TextStyle(color: Colors.grey)),
                            onTap: () => _launchUrl('https://www.quikeai.com/report'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Legal
                  _buildSectionTitle('Legal'),
                  _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.privacy_tip, color: Colors.blueAccent),
                            title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () {
                              Navigator.pushNamed(context, '/privacy');
                            },
                          ),
                          const Divider(color: Colors.grey),
                          ListTile(
                            leading: const Icon(Icons.gavel, color: Colors.blueAccent),
                            title: const Text('Terms of Service', style: TextStyle(color: Colors.white)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () {
                              Navigator.pushNamed(context, '/terms');
                            },
                          ),
                          const Divider(color: Colors.grey),
                          ListTile(
                            leading: const Icon(Icons.verified_user, color: Colors.blueAccent),
                            title: const Text('Data Usage', style: TextStyle(color: Colors.white)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () {
                              Navigator.pushNamed(context, '/data-usage');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Copyright
                  Center(
                    child: Text(
                      ' 2023 Quike AI. All rights reserved.',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.grey[850],
      child: child,
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blueAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember({
    required String name,
    required String role,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: const Icon(
              Icons.people,
              size: 40,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
