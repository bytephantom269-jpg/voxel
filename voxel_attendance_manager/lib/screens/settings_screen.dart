import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure Late Time',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Current Late Time: ${settingsProvider.lateTimeDisplay}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Hour (0-23)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: settingsProvider.lateHour.toDouble(),
                              min: 0,
                              max: 23,
                              divisions: 23,
                              label: settingsProvider.lateHour.toString(),
                              onChanged: (value) {
                                settingsProvider.setLateTime(
                                  value.toInt(),
                                  settingsProvider.lateMinute,
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              settingsProvider.lateHour.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Minute (0-59)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: settingsProvider.lateMinute.toDouble(),
                              min: 0,
                              max: 59,
                              divisions: 59,
                              label: settingsProvider.lateMinute.toString(),
                              onChanged: (value) {
                                settingsProvider.setLateTime(
                                  settingsProvider.lateHour,
                                  value.toInt(),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              settingsProvider.lateMinute.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'About',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppConfig.appName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Version ${AppConfig.appVersion}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'A fully offline attendance tracking application with barcode scanning and configurable late arrival detection. All data is stored locally on your device.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
