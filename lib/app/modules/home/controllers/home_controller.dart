// File: /lib/app/modules/home/controllers/home_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/order_model.dart';
import '../../../services/notification_service.dart';

class HomeController extends GetxController {
  // ... (semua properti dan konstanta lainnya tetap sama) ...
    // ─── Reactive State ────────────────────────────────────────────────────────

  /// Key format: "YYYY-MM-DD"
  final schedules = <String, DailySchedule>{}.obs;

  final currentYear = DateTime.now().year.obs;

  /// Kapasitas default per hari (bisa diubah user nanti)
  final defaultDailyCapacity = 3.obs;

  static const String _storageKey = 'boutique_schedules_data';

  // ─── Constants ─────────────────────────────────────────────────────────────

  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> monthNamesId = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadFromPrefs(); // Muat data dari local storage saat aplikasi dibuka
  }

  // ─── Local Persistence (Shared Preferences) ────────────────────────────────

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        // Decode string JSON kembali ke Map<String, dynamic>
        final Map<String, dynamic> decodedData = jsonDecode(jsonString);
        final loadedSchedules = <String, DailySchedule>{};

        // Konversi map hasil decode menjadi object DailySchedule
        decodedData.forEach((key, value) {
          loadedSchedules[key] =
              DailySchedule.fromJson(value as Map<String, dynamic>);
        });

        schedules.assignAll(loadedSchedules);
      } else {
        // Jika aplikasi baru pertama kali diinstal/dibuka, pakai dummy data
        _generateDummyData();
        _saveToPrefs();
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
      _generateDummyData(); // Fallback jika gagal parse data korup
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Ubah Object DailySchedule menjadi Map agar bisa diubah ke JSON String
      final mapToSave =
          schedules.map((key, value) => MapEntry(key, value.toJson()));
      final jsonString = jsonEncode(mapToSave);

      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving schedules: $e');
    }
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void nextYear() => currentYear.value++;
  void previousYear() => currentYear.value--;

  // ─── Date Helpers ──────────────────────────────────────────────────────────

  String formatDateKey(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int getDaysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  int getFirstWeekdayOfMonth(int year, int month) =>
      DateTime(year, month, 1).weekday; // 1=Mon ... 7=Sun

  String formatDisplayDate(DateTime date) =>
      '${date.day} ${monthNamesId[date.month - 1]} ${date.year}';

  // ─── Capacity & Color ──────────────────────────────────────────────────────

  double getCapacityForDate(DateTime date) {
    final key = formatDateKey(date);
    return schedules[key]?.capacityPercentage ?? 0.0;
  }

  DailySchedule? getScheduleForDate(DateTime date) =>
      schedules[formatDateKey(date)];

  List<OrderModel> getOrdersForDate(DateTime date) =>
      schedules[formatDateKey(date)]?.orders ?? [];

  bool isDateFull(DateTime date) =>
      schedules[formatDateKey(date)]?.isFull ?? false;

  int getRemainingSlots(DateTime date) {
    final key = formatDateKey(date);
    final schedule = schedules[key];
    if (schedule == null) return defaultDailyCapacity.value;
    return schedule.remainingSlots;
  }

  // ─── CRUD Operations ───────────────────────────────────────────────────────

  void addOrder(DateTime date, OrderModel newOrder) {
    final key = formatDateKey(date);

    if (!schedules.containsKey(key)) {
      schedules[key] = DailySchedule(
        date: date,
        orders: [],
        maxCapacity: defaultDailyCapacity.value,
      );
    }

    final schedule = schedules[key]!;

    if (schedule.isFull) {
      _showError(
        'Kapasitas Penuh',
        'Tanggal ini sudah penuh (${schedule.maxCapacity} order).',
      );
      return;
    }

    schedules[key] = schedule.withAddedOrder(newOrder);
    schedules.refresh();
    
    _saveToPrefs(); // Simpan ke local storage

    // Jadwalkan notifikasi
    NotificationService().scheduleOrderReminders(newOrder);

    _showSuccess('Order ditambahkan untuk ${newOrder.customerName}');
  }

  void updateOrder(DateTime date, OrderModel updatedOrder) {
    final key = formatDateKey(date);
    if (!schedules.containsKey(key)) return;

    schedules[key] = schedules[key]!.withUpdatedOrder(updatedOrder);
    schedules.refresh();
    
    _saveToPrefs(); // Simpan ke local storage

    // Reschedule notifikasi (deadline mungkin berubah)
    NotificationService().rescheduleOrderReminders(updatedOrder);

    _showSuccess('Order ${updatedOrder.customerName} diperbarui');
  }

  void deleteOrder(DateTime date, String orderId) {
    final key = formatDateKey(date);
    if (!schedules.containsKey(key)) return;

    final updated = schedules[key]!.withRemovedOrder(orderId);

    if (updated.orders.isEmpty) {
      schedules.remove(key);
    } else {
      schedules[key] = updated;
    }
    schedules.refresh();
    
    _saveToPrefs(); // Simpan ke local storage

    // Batalkan notifikasi
    NotificationService().cancelOrderReminders(orderId);

    Get.snackbar(
      'Berhasil',
      'Order berhasil dihapus',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ─── Statistics ────────────────────────────────────────────────────────────

  ScheduleStats getMonthlyStats(int year, int month) {
    int totalOrders = 0;
    double totalRevenue = 0;
    double totalCollected = 0;
    double totalReceivables = 0;
    int paidOffCount = 0;
    int pendingCount = 0;

    schedules.forEach((_, schedule) {
      if (schedule.date.year == year && schedule.date.month == month) {
        for (final order in schedule.orders) {
          totalOrders++;
          totalRevenue += order.totalPrice;
          totalCollected += order.dpAmount;
          totalReceivables += order.remainingDebt;
          if (order.isPaidOff) {
            paidOffCount++;
          } else {
            pendingCount++;
          }
        }
      }
    });

    return ScheduleStats(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      totalCollected: totalCollected,
      totalReceivables: totalReceivables,
      paidOffCount: paidOffCount,
      pendingCount: pendingCount,
    );
  }

  ScheduleStats getYearlyStats(int year) {
    return List.generate(12, (i) => getMonthlyStats(year, i + 1))
        .fold(const ScheduleStats(), (acc, s) => acc + s);
  }

  // ─── Snackbar Helpers ──────────────────────────────────────────────────────

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      '✅ Berhasil',
      message,
      backgroundColor: const Color(0xFF1D3557),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ─── Dummy Data (DIUPDATE) ─────────────────────────────────────────────────

  void _generateDummyData() {
    final today = DateTime.now();
    final entryDate1 = today.subtract(const Duration(days: 7));
    final entryDate2 = today.subtract(const Duration(days: 5));

    // Hari ini — 2/3 terisi
    final keyToday = formatDateKey(today);
    schedules[keyToday] = DailySchedule(
      date: today,
      maxCapacity: 3,
      orders: [
        OrderModel(
          id: 'dummy_1',
          customerName: 'Nyonya Ayu',
          clothingType: 'Kebaya Modern',
          deadline: today,
          entryDate: entryDate1, // UPDATED
          totalPrice: 1500000,
          dpAmount: 500000,
          addons: 'Titip beli puring putih 3m',
        ),
        OrderModel(
          id: 'dummy_2',
          customerName: 'Nona Bella',
          clothingType: 'Dress Pesta',
          deadline: today,
          entryDate: entryDate2, // UPDATED
          totalPrice: 800000,
          dpAmount: 800000,
        ),
      ],
    );

    // Besok — penuh (3/3) → warna emas
    final tomorrow = today.add(const Duration(days: 1));
    final keyTomorrow = formatDateKey(tomorrow);
    schedules[keyTomorrow] = DailySchedule(
      date: tomorrow,
      maxCapacity: 3,
      orders: List.generate(
        3,
        (i) => OrderModel(
          id: 'dummy_t$i',
          customerName: 'Klien ${i + 1}',
          clothingType: 'Blouse Batik',
          deadline: tomorrow,
          entryDate: today.subtract(const Duration(days: 10)), // UPDATED
          totalPrice: 500000,
          dpAmount: 250000,
        ),
      ),
    );

    // 3 hari lagi — 1/3
    final in3Days = today.add(const Duration(days: 3));
    final key3 = formatDateKey(in3Days);
    schedules[key3] = DailySchedule(
      date: in3Days,
      maxCapacity: 3,
      orders: [
        OrderModel(
          id: 'dummy_3',
          customerName: 'Ibu Citra',
          clothingType: 'Gamis',
          deadline: in3Days,
          entryDate: today, // UPDATED
          totalPrice: 1200000,
          dpAmount: 600000,
        ),
      ],
    );
  }
}