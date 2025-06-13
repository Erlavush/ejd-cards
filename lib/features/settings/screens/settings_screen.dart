// lib/features/settings/screens/settings_screen.dart

import 'package:ejd_cards/features/settings/screens/about_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/services/settings_service.dart';
import '../../../main.dart'; // To access AppThemeMode and themeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  late int _defaultFrontTime;
  late int _defaultBackTime;
  late bool _autoplayShuffle;
  late bool _autoplayLoop;
  bool _isLoading = true;

  final _frontTimeController = TextEditingController();
  final _backTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    _defaultFrontTime = await _settingsService.getDefaultFrontTime();
    _defaultBackTime = await _settingsService.getDefaultBackTime();
    _autoplayShuffle = await _settingsService.getAutoplayShuffle();
    _autoplayLoop = await _settingsService.getAutoplayLoop();

    _frontTimeController.text = _defaultFrontTime.toString();
    _backTimeController.text = _defaultBackTime.toString();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _frontTimeController.dispose();
    _backTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveDefaultFrontTime() async {
    final newTime = int.tryParse(_frontTimeController.text);
    if (newTime != null && newTime > 0) {
      await _settingsService.setDefaultFrontTime(newTime);
      if (mounted) {
        setState(() {
          _defaultFrontTime = newTime;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default front time saved!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid time. Please enter a positive number.')),
      );
      _frontTimeController.text = _defaultFrontTime.toString();
    }
  }

  Future<void> _saveDefaultBackTime() async {
    final newTime = int.tryParse(_backTimeController.text);
    if (newTime != null && newTime > 0) {
      await _settingsService.setDefaultBackTime(newTime);
      if (mounted) {
        setState(() {
          _defaultBackTime = newTime;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default back time saved!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid time. Please enter a positive number.')),
      );
      _backTimeController.text = _defaultBackTime.toString();
    }
  }

  Future<void> _saveAutoplayShuffle(bool value) async {
    await _settingsService.setAutoplayShuffle(value);
    if (mounted) {
      setState(() {
        _autoplayShuffle = value;
      });
    }
  }

  Future<void> _saveAutoplayLoop(bool value) async {
    await _settingsService.setAutoplayLoop(value);
    if (mounted) {
      setState(() {
        _autoplayLoop = value;
      });
    }
  }

  Future<void> _changeTheme(AppThemeMode? newMode) async {
    if (newMode == null) return;
    themeNotifier.value = newMode;
    await _settingsService.setThemeMode(newMode);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Icon(Iconsax.brush_1),
            title: const Text('Theme'),
            trailing: DropdownButton<AppThemeMode>(
              value: themeNotifier.value,
              items: const [
                DropdownMenuItem(value: AppThemeMode.system, child: Text('System Default')),
                DropdownMenuItem(value: AppThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: AppThemeMode.dark, child: Text('Dark (Grey)')),
                DropdownMenuItem(value: AppThemeMode.amoled, child: Text('Dark (AMOLED)')),
              ],
              onChanged: _changeTheme,
            ),
          ),
          const Divider(height: 40),
          Text('Autoplay Defaults', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildTimeSettingRow(
            label: 'Front Display Time (seconds):',
            controller: _frontTimeController,
            onSave: _saveDefaultFrontTime,
          ),
          const SizedBox(height: 16),
          _buildTimeSettingRow(
            label: 'Back Display Time (seconds):',
            controller: _backTimeController,
            onSave: _saveDefaultBackTime,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: const Text('Shuffle Cards by Default'),
            value: _autoplayShuffle,
            onChanged: _saveAutoplayShuffle,
            secondary: const Icon(Iconsax.shuffle),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: const Text('Loop Deck by Default'),
            subtitle: const Text('Restart deck automatically when finished.'),
            value: _autoplayLoop,
            onChanged: _saveAutoplayLoop,
            secondary: const Icon(Iconsax.repeat),
          ),
          const Divider(height: 40),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Icon(Iconsax.info_circle),
            title: const Text('About & Data Management'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const AboutPage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSettingRow({
    required String label,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final num = int.tryParse(value.trim());
              if (num == null || num <= 0) return 'Must be >0';
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Iconsax.save_2),
          tooltip: 'Save Time',
          onPressed: onSave,
          color: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}