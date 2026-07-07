import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // To access themeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLightMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePref();
  }

  Future<void> _loadThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLightMode = prefs.getBool("isLightMode") ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLightMode", value);
    setState(() {
      _isLightMode = value;
    });
    // Toggle main app theme
    themeNotifier.value = value ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.black54,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            "Appearance",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF13233D),
            child: SwitchListTile(
              secondary: Icon(
                _isLightMode ? Icons.light_mode : Icons.dark_mode,
                color: _isLightMode ? Colors.amber : const Color(0xFF00BFA5),
              ),
              title: const Text("Light Mode Theme"),
              value: _isLightMode,
              onChanged: _toggleTheme,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Support & Information",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF13233D),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF9B91FF)),
                  title: const Text("Help & Support"),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                  onTap: () {
                    Navigator.pushNamed(context, "/help-support");
                  },
                ),
                const Divider(height: 1, indent: 56, endIndent: 16, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF00BFA5)),
                  title: const Text("About App"),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                  onTap: () {
                    Navigator.pushNamed(context, "/about");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}