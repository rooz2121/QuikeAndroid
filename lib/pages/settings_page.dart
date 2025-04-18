import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/date_time_utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isDarkMode = true;
  bool _isNotificationsEnabled = true;
  String _selectedLanguage = 'English';
  double _fontSize = 16.0;
  bool _isLoading = true;
  bool _isSaving = false;
  
  final List<String> _languages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _supabaseService.getUserSettings();
      
      if (settings != null) {
        setState(() {
          _isDarkMode = settings['dark_mode'] ?? true;
          _isNotificationsEnabled = settings['notifications_enabled'] ?? true;
          _selectedLanguage = settings['language'] ?? 'English';
          _fontSize = (settings['font_size'] ?? 16.0).toDouble();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _supabaseService.saveUserSettings({
        'dark_mode': _isDarkMode,
        'notifications_enabled': _isNotificationsEnabled,
        'language': _selectedLanguage,
        'font_size': _fontSize,
        'updated_at': DateTimeUtils.nowForSupabase(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Note: We're using a dropdown for language selection instead of a dialog

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance Section
                  _buildSectionHeader('Appearance'),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: 'Dark Mode',
                          subtitle: 'Use dark theme throughout the app',
                          value: _isDarkMode,
                          onChanged: (value) {
                            setState(() {
                              _isDarkMode = value;
                            });
                          },
                          icon: Icons.dark_mode,
                        ),
                        const Divider(color: Colors.grey),
                        ListTile(
                          leading: const Icon(Icons.text_fields, color: Colors.blueAccent),
                          title: const Text('Font Size', style: TextStyle(color: Colors.white)),
                          subtitle: Text('${_fontSize.toInt()} px', style: TextStyle(color: Colors.grey[400])),
                          trailing: SizedBox(
                            width: 150,
                            child: Slider(
                              value: _fontSize,
                              min: 12.0,
                              max: 24.0,
                              divisions: 6,
                              label: _fontSize.toInt().toString(),
                              activeColor: Colors.blueAccent,
                              inactiveColor: Colors.blueAccent.withOpacity(0.3),
                              onChanged: (value) {
                                setState(() {
                                  _fontSize = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Preferences Section
                  _buildSectionHeader('Preferences'),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.language, color: Colors.blueAccent),
                          title: const Text('Language', style: TextStyle(color: Colors.white)),
                          subtitle: Text(_selectedLanguage, style: TextStyle(color: Colors.grey[400])),
                          trailing: DropdownButton<String>(
                            value: _selectedLanguage,
                            dropdownColor: Colors.grey[850],
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedLanguage = newValue;
                                });
                              }
                            },
                            items: _languages.map<DropdownMenuItem<String>>(
                              (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(color: Colors.white)),
                                );
                              },
                            ).toList(),
                            underline: Container(),
                          ),
                        ),
                        const Divider(color: Colors.grey),
                        _buildSwitchTile(
                          title: 'Notifications',
                          subtitle: 'Receive notifications from the app',
                          value: _isNotificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _isNotificationsEnabled = value;
                            });
                          },
                          icon: Icons.notifications,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Account Section
                  _buildSectionHeader('Account'),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.blueAccent),
                          title: const Text('Profile', style: TextStyle(color: Colors.white)),
                          subtitle: Text(_supabaseService.currentUser?.email ?? 'Not logged in', style: TextStyle(color: Colors.grey[400])),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            // Navigate to profile page
                          },
                        ),
                        const Divider(color: Colors.grey),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.blueAccent),
                          title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.grey[900],
                                title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                                content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('CANCEL', style: TextStyle(color: Colors.blueAccent)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('SIGN OUT', style: TextStyle(color: Colors.blueAccent)),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirm == true) {
                              await _supabaseService.signOut();
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, '/');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Data & Privacy Section
                  _buildSectionHeader('Data & Privacy'),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete_forever, color: Colors.blueAccent),
                          title: const Text('Clear Chat History', style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.grey[900],
                                title: const Text('Clear Chat History', style: TextStyle(color: Colors.white)),
                                content: const Text('This will delete all your chat history. This action cannot be undone. Are you sure?', style: TextStyle(color: Colors.white)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('CANCEL', style: TextStyle(color: Colors.blueAccent)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('CLEAR', style: TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirm == true) {
                              // Show loading indicator
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Clearing chat history...')),
                              );
                              
                              try {
                                await _supabaseService.clearAllChatSessions();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Chat history cleared successfully')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error clearing chat history: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        const Divider(color: Colors.grey),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip, color: Colors.blueAccent),
                          title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.pushNamed(context, '/privacy');
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // About Section
                  _buildSectionHeader('About'),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info, color: Colors.blueAccent),
                          title: const Text('About Quike AI', style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.pushNamed(context, '/about');
                          },
                        ),
                        const Divider(color: Colors.grey),
                        ListTile(
                          leading: const Icon(Icons.help, color: Colors.blueAccent),
                          title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.pushNamed(context, '/help');
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // App Version
                  Center(
                    child: Text(
                      'Quike AI v1.0.0',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: Colors.blueAccent),
      activeColor: Colors.blueAccent,
    );
  }
}
