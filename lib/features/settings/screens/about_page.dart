// lib/features/settings/screens/about_page.dart

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/deck_persistence_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../main.dart'; // To reset themeNotifier and get AppThemeMode

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${packageInfo.version} (Build ${packageInfo.buildNumber})';
      });
    }
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All App Data?'),
        content: const Text('This action is irreversible. All your decks and settings will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // Perform the reset
              await DeckPersistenceService().deleteAllDecks();

              final settings = SettingsService();
              await settings.setThemeMode(AppThemeMode.system);
              await settings.setDefaultFrontTime(SettingsService.defaultFrontSeconds);
              await settings.setDefaultBackTime(SettingsService.defaultBackSeconds);
              await settings.setAutoplayShuffle(SettingsService.defaultShuffle);
              await settings.setAutoplayLoop(SettingsService.defaultLoop);

              // Update the global notifier to reflect the theme reset instantly
              themeNotifier.value = AppThemeMode.system;

              // Close the dialog
              if (mounted) Navigator.of(ctx).pop();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App data has been reset.')),
                );
                // Pop all the way back to the deck list, which will then be forced to refresh
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Iconsax.document_code),
            title: const Text('App Version'),
            subtitle: Text(_version),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Iconsax.code),
            title: Text('Framework'),
            subtitle: Text('Built with Flutter'),
          ),
          const Divider(),
          const SizedBox(height: 32),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Iconsax.trash, size: 20),
              label: const Text('Reset All App Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: _showResetConfirmationDialog,
            ),
          ),
        ],
      ),
    );
  }
}