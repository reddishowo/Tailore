// File: /lib/app/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/models/order_model.dart';

class NotificationService {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _channelId = 'boutique_reminder_channel';
  static const String _channelName = 'Boutique Reminders';
  static const String _channelDesc = 'Reminder jadwal jahitan butik';
  static const Color _brandColor = Color(0xFF1D3557);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Atur ke Asia/Jakarta (WIB). Ganti ke 'Asia/Makassar' untuk WITA.
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permission untuk Android 13+ (API 33+)
    await _requestAndroidPermission();

    _initialized = true;
  }

  Future<void> _requestAndroidPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigasi ke halaman order jika diperlukan
    // Get.toNamed(Routes.ORDER_DETAIL, arguments: response.payload);
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ─── Notification Details ──────────────────────────────────────────────────

  NotificationDetails get _notifDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          color: _brandColor,
          enableLights: true,
          ledColor: _brandColor,
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  // ─── ID Generation ─────────────────────────────────────────────────────────

  /// Generate ID unik berdasarkan orderId + dayOffset
  /// Menggunakan modulo untuk tetap dalam range integer 32-bit
  int _generateId(String orderId, int dayOffset) {
    return ((orderId.hashCode * 31) + dayOffset).abs() % 0x7FFFFFFF;
  }

  // ─── Schedule Reminders ────────────────────────────────────────────────────

  /// Jadwalkan reminder H-3, H-2, H-1 jam 08:00 WIB
  Future<void> scheduleOrderReminders(OrderModel order) async {
    if (!_initialized) await init();

    const reminderDays = [3, 2, 1];

    for (final days in reminderDays) {
      final reminderDateTime = _getReminderTime(order.deadline, days);

      // Lewati jika waktu sudah lampau
      if (reminderDateTime.isBefore(DateTime.now())) continue;

      try {
        await _plugin.zonedSchedule(
          _generateId(order.id, days),
          _buildTitle(order, days),
          _buildBody(order, days),
          tz.TZDateTime.from(reminderDateTime, tz.local),
          _notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: order.id, // Bisa dipakai untuk navigasi saat notif di-tap
        );
        debugPrint(
            '✅ Reminder H-$days dijadwalkan untuk ${order.customerName} '
            'pada ${reminderDateTime.toString()}');
      } catch (e) {
        debugPrint('❌ Gagal jadwalkan notifikasi H-$days: $e');
      }
    }
  }

  /// Ambil waktu reminder (H-x jam 08:00)
  DateTime _getReminderTime(DateTime deadline, int daysBefore) {
    final date = deadline.subtract(Duration(days: daysBefore));
    return DateTime(date.year, date.month, date.day, 8, 0);
  }

  String _buildTitle(OrderModel order, int days) =>
      '🧵 Deadline H-$days: ${order.customerName}';

  String _buildBody(OrderModel order, int days) {
    final suffix = days == 1 ? 'Besok deadline!' : '$days hari lagi deadline!';
    return '${order.clothingType} untuk ${order.customerName}. $suffix';
  }

  // ─── Cancel Reminders ──────────────────────────────────────────────────────

  /// Batalkan semua reminder untuk satu order
  Future<void> cancelOrderReminders(String orderId) async {
    if (!_initialized) await init();
    try {
      await Future.wait([
        _plugin.cancel(_generateId(orderId, 1)),
        _plugin.cancel(_generateId(orderId, 2)),
        _plugin.cancel(_generateId(orderId, 3)),
      ]);
      debugPrint('🗑️ Reminder dibatalkan untuk order $orderId');
    } catch (e) {
      debugPrint('❌ Gagal batalkan notifikasi: $e');
    }
  }

  /// Batalkan SEMUA notifikasi aplikasi
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('🗑️ Semua notifikasi dibatalkan');
  }

  // ─── Reschedule (untuk update order) ──────────────────────────────────────

  Future<void> rescheduleOrderReminders(OrderModel order) async {
    await cancelOrderReminders(order.id);
    await scheduleOrderReminders(order);
  }
}