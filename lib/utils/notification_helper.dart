import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();

  /// Request notification permission and show dialog if needed
  static Future<bool> requestPermission(BuildContext context) async {
    final bool? granted = await _notificationService.requestPermission();
    
    if (granted == false && context.mounted) {
      _showPermissionDialog(context);
      return false;
    }
    
    return granted ?? false;
  }

  /// Show dialog to explain why notification permission is needed
  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izin Notifikasi'),
          content: const Text(
            'Aplikasi memerlukan izin notifikasi untuk mengingatkan Anda tentang deadline quest yang akan berakhir dalam 15 menit.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tidak Sekarang'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // User can manually enable in settings
                _showSettingsDialog(context);
              },
              child: const Text('Aktifkan'),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog to guide user to app settings
  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aktifkan Notifikasi'),
          content: const Text(
            'Untuk mengaktifkan notifikasi reminder quest:\n\n'
            '1. Buka Pengaturan aplikasi\n'
            '2. Pilih Notifikasi\n'
            '3. Aktifkan semua notifikasi\n\n'
            'Atau restart aplikasi untuk diminta izin lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    final bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    
    return result ?? false;
  }

  /// Show a success message when notification is scheduled
  static void showScheduledMessage(BuildContext context, String questTitle) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder diatur untuk quest: $questTitle'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show an info message about deadline reminder
  static void showDeadlineInfo(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda akan mendapat reminder 15 menit sebelum deadline quest'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
