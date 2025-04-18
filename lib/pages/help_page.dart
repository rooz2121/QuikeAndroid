import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

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
        title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
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
                        Icons.help_outline,
                        size: 60,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How can we help you?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find answers to common questions and learn how to use Quike AI effectively.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // FAQ Section
              _buildSectionHeader('Frequently Asked Questions'),
              const SizedBox(height: 8),
              _buildExpandableCard(
                title: 'What is Quike AI?',
                content: 'Quike AI is an intelligent assistant powered by advanced language models. It can help you with information, creative writing, problem-solving, and more.',
              ),
              _buildExpandableCard(
                title: 'How do I start a new chat?',
                content: 'To start a new chat, tap on the "+" button in the bottom right corner of the main chat screen. This will create a new conversation with Quike AI.',
              ),
              _buildExpandableCard(
                title: 'How do I access my chat history?',
                content: 'Your chat history is accessible from the main screen. Swipe from the left edge or tap the menu icon to open the sidebar, where you can see all your previous conversations.',
              ),
              _buildExpandableCard(
                title: 'Is my data secure?',
                content: 'Yes, we take data security very seriously. All your conversations are encrypted and stored securely. You can delete your chat history at any time from the Settings page.',
              ),
              _buildExpandableCard(
                title: 'How do I change app settings?',
                content: 'To change app settings, open the sidebar menu and tap on "Settings". There you can customize appearance, notifications, language, and other preferences.',
              ),
              const SizedBox(height: 32),
              // Getting Started Guide
              _buildSectionHeader('Getting Started'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGuideStep(
                        context,
                        number: '1',
                        title: 'Create an account',
                        description: 'Sign up with your email address to get started with Quike AI.',
                      ),
                      const Divider(),
                      _buildGuideStep(
                        context,
                        number: '2',
                        title: 'Start a conversation',
                        description: 'Tap the new chat button and start asking questions or having a conversation.',
                      ),
                      const Divider(),
                      _buildGuideStep(
                        context,
                        number: '3',
                        title: 'Explore features',
                        description: 'Try different types of questions and requests to explore the capabilities of Quike AI.',
                      ),
                      const Divider(),
                      _buildGuideStep(
                        context,
                        number: '4',
                        title: 'Customize your experience',
                        description: 'Visit the Settings page to customize the app according to your preferences.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Tips & Tricks
              _buildSectionHeader('Tips & Tricks'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTipItem(
                        context,
                        icon: Icons.lightbulb_outline,
                        title: 'Be specific in your questions',
                        description: 'The more specific your questions, the more helpful and accurate the responses will be.',
                      ),
                      const Divider(),
                      _buildTipItem(
                        context,
                        icon: Icons.history,
                        title: 'Review conversation history',
                        description: 'You can scroll up to review the entire conversation history within a chat session.',
                      ),
                      const Divider(),
                      _buildTipItem(
                        context,
                        icon: Icons.text_format,
                        title: 'Use formatting in your messages',
                        description: 'You can use *asterisks* for bold text and _underscores_ for italic text in your messages.',
                      ),
                      const Divider(),
                      _buildTipItem(
                        context,
                        icon: Icons.thumb_up_alt_outlined,
                        title: 'Provide feedback',
                        description: 'Use the like and dislike buttons to provide feedback on AI responses, helping improve the system.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Contact Support
              _buildSectionHeader('Contact Support'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email Support'),
                        subtitle: const Text('support@quikeai.com'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _launchUrl('mailto:support@quikeai.com'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.chat),
                        title: const Text('Live Chat'),
                        subtitle: const Text('Chat with our support team'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _launchUrl('https://www.quikeai.com/support'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.help_center),
                        title: const Text('Help Center'),
                        subtitle: const Text('Browse our knowledge base'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _launchUrl('https://www.quikeai.com/help'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Feedback
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildFeedbackDialog(context),
                    );
                  },
                  icon: const Icon(Icons.feedback),
                  label: const Text('Send Feedback'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
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

  Widget _buildExpandableCard({required String title, required String content}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconColor: Colors.blueAccent,
        collapsedIconColor: Colors.grey,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              content,
              style: TextStyle(height: 1.5, color: Colors.grey[300]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context, {
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Send Feedback'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'We appreciate your feedback to help improve Quike AI.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: feedbackController,
            decoration: const InputDecoration(
              hintText: 'Enter your feedback here',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            // Process feedback
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thank you for your feedback!')),
            );
            Navigator.pop(context);
          },
          child: const Text('SUBMIT'),
        ),
      ],
    );
  }
}
