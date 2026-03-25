// File: /lib/app/modules/home/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Import package intl
import '../controllers/home_controller.dart';
import '../../../data/models/order_model.dart';

// ... (HomeView dan widget lainnya di atas _OrderCard tetap sama) ...
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  // ─── Brand Colors ──────────────────────────────────────────────────────────
  static const Color navy = Color(0xFF1D3557);
  static const Color gold = Color(0xFFD4AF37);
  static const Color cream = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: _buildAppBar(context),
      body: Obx(() {
        final year = controller.currentYear.value;
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: 12,
          itemBuilder: (ctx, i) => _MonthCard(
            key: ValueKey('$year-${i + 1}'),
            year: year,
            month: i + 1,
            controller: controller,
            onDayTap: (date) => _showDailyOrderSheet(ctx, date),
            onHeaderTap: () => _showMonthlyStats(context, year, i + 1),
          ),
        );
      }),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: cream,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28, color: navy),
        onPressed: controller.previousYear,
        tooltip: 'Tahun Sebelumnya',
      ),
      title: Obx(() => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              'Jadwal ${controller.currentYear.value}',
              key: ValueKey(controller.currentYear.value),
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          )),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded, size: 26, color: navy),
          onPressed: () => _showYearlyStats(context),
          tooltip: 'Laporan Tahunan',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 28, color: navy),
          onPressed: controller.nextYear,
          tooltip: 'Tahun Berikutnya',
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BOTTOM SHEET — DAFTAR ORDER PER TANGGAL
  // ──────────────────────────────────────────────────────────────────────────

  void _showDailyOrderSheet(BuildContext context, DateTime date) {
    Get.bottomSheet(
      _DailyOrderSheet(
        date: date,
        controller: controller,
        onAddTap: () {
          Get.back();
          _showAddEditOrderDialog(context, date);
        },
        onEditTap: (order) {
          Get.back();
          _showAddEditOrderDialog(context, date, order: order);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIALOG — FORM TAMBAH / EDIT ORDER
  // ──────────────────────────────────────────────────────────────────────────

  void _showAddEditOrderDialog(
    BuildContext context,
    DateTime date, {
    OrderModel? order,
  }) {
    Get.dialog(
      _OrderFormDialog(
        date: date,
        existingOrder: order,
        controller: controller,
        onSaved: () => _showDailyOrderSheet(context, date),
      ),
      barrierDismissible: false,
    );
  }
  
  // ──────────────────────────────────────────────────────────────────────────
  // BOTTOM SHEET — STATISTIK BULANAN
  // ──────────────────────────────────────────────────────────────────────────

  void _showMonthlyStats(BuildContext context, int year, int month) {
    Get.bottomSheet(
      _MonthlyStatsSheet(controller: controller, year: year, month: month),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BOTTOM SHEET — STATISTIK TAHUNAN
  // ──────────────────────────────────────────────────────────────────────────

  void _showYearlyStats(BuildContext context) {
    Get.bottomSheet(
      _YearlyStatsSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MONTH CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    super.key,
    required this.year,
    required this.month,
    required this.controller,
    required this.onDayTap,
    required this.onHeaderTap,
  });

  final int year;
  final int month;
  final HomeController controller;
  final void Function(DateTime) onDayTap;
  final VoidCallback onHeaderTap;

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = controller.getDaysInMonth(year, month);
    final firstWeekday = controller.getFirstWeekdayOfMonth(year, month);
    final emptyBoxes = firstWeekday - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bulan (dibuat tappable)
          InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        HomeController.monthNames[month - 1],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: HomeView.navy,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.insights_rounded, size: 16, color: HomeView.navy.withOpacity(0.4)),
                    ],
                  ),
                  _MonthOrderBadge(year: year, month: month, controller: controller),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Day-of-week headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayLabels.map((d) => SizedBox(
              width: 32,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth + emptyBoxes,
            itemBuilder: (_, index) {
              if (index < emptyBoxes) return const SizedBox();
              final day = index - emptyBoxes + 1;
              final date = DateTime(year, month, day);
              return _DayCell(
                date: date,
                controller: controller,
                onTap: () => onDayTap(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MONTH ORDER BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _MonthOrderBadge extends StatelessWidget {
  const _MonthOrderBadge({
    required this.year,
    required this.month,
    required this.controller,
  });

  final int year;
  final int month;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.getMonthlyStats(year, month);
      if (stats.totalOrders == 0) return const SizedBox();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: HomeView.navy.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${stats.totalOrders} order',
          style: const TextStyle(
            fontSize: 11,
            color: HomeView.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY CELL WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.controller,
    required this.onTap,
  });

  final DateTime date;
  final HomeController controller;
  final VoidCallback onTap;

  Color _cellColor(int orderCount) {
    switch (orderCount) {
      case 0:
        return Colors.white;
      case 1:
        return const Color(0xFFBDD5EA); // Biru pastel
      case 2:
        return HomeView.gold; // Emas
      default: // Handles 3 or more orders
        return const Color(0xFFE57373); // Merah (seperti Colors.red[400])
    }
  }

  Color _textColor(int orderCount) {
    if (orderCount == 0) return Colors.black87;
    if (orderCount == 1) return HomeView.navy;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return Obx(() {
      final orderCount = controller.getOrdersForDate(date).length;
      final bg = _cellColor(orderCount);
      final fg = _textColor(orderCount);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
              border: isToday
                  ? Border.all(color: HomeView.navy, width: 2)
                  : Border.all(
                      color: orderCount > 0
                          ? Colors.transparent
                          : Colors.grey.withOpacity(0.15),
                    ),
              boxShadow: _buildShadow(orderCount),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: (isToday || orderCount > 0)
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  List<BoxShadow> _buildShadow(int orderCount) {
    switch (orderCount) {
      case 1: // Shadow biru
        return [
          BoxShadow(
            color: HomeView.navy.withOpacity(0.18),
            blurRadius: 4,
          )
        ];
      case 2: // Shadow emas
        return [
          BoxShadow(
            color: HomeView.gold.withOpacity(0.45),
            blurRadius: 6,
            spreadRadius: 1,
          )
        ];
      case 3: // Shadow merah
      default:
        if (orderCount < 3) return [];
        return [
          BoxShadow(
            color: Colors.red.withOpacity(0.45),
            blurRadius: 6,
            spreadRadius: 1,
          )
        ];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY ORDER SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _DailyOrderSheet extends StatelessWidget {
  const _DailyOrderSheet({
    required this.date,
    required this.controller,
    required this.onAddTap,
    required this.onEditTap,
  });

  final DateTime date;
  final HomeController controller;
  final VoidCallback onAddTap;
  final void Function(OrderModel) onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.65,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: HomeView.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Obx(() {
        final orders = controller.getOrdersForDate(date);
        final slots = controller.getRemainingSlots(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.formatDisplayDate(date),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: HomeView.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${orders.length} order · $slots slot tersisa',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                _CapacityDots(
                  filled: orders.length,
                  total: controller.getScheduleForDate(date)?.maxCapacity ??
                      controller.defaultDailyCapacity.value,
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey.shade200),

            // Order list
            Expanded(
              child: orders.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (_, i) => _OrderCard(
                        order: orders[i],
                        onEdit: () => onEditTap(orders[i]),
                        onDelete: () =>
                            controller.deleteOrder(date, orders[i].id),
                      ),
                    ),
            ),

            // Add button
            if (slots > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Tambah Order Baru',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeView.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onAddTap,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAPACITY DOTS INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class _CapacityDots extends StatelessWidget {
  const _CapacityDots({required this.filled, required this.total});
  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(left: 5),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? (filled >= total ? HomeView.gold : HomeView.navy)
                : Colors.grey.shade200,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER CARD (UPDATED)
// ─────────────────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onEdit,
    required this.onDelete,
  });

  final OrderModel order;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // Helper untuk format tanggal masuk
  String _formatEntryDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('dismiss_${order.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Hapus Order?'),
            content: Text(
              'Order ${order.customerName} akan dihapus permanen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent),
                onPressed: () => Get.back(result: true),
                child: const Text('Hapus',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 65, // Sedikit lebih tinggi untuk mengakomodasi baris baru
              decoration: BoxDecoration(
                color: order.isPaidOff
                    ? Colors.green.shade400
                    : HomeView.gold,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: HomeView.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.clothingType,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4), // ADDED Spacing
                  // ADDED: Tampilan Tanggal Masuk
                  Row(
                    children: [
                      Icon(Icons.login_rounded, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Masuk: ${_formatEntryDate(order.entryDate)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (order.addons.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📦 ${order.addons}',
                      style: TextStyle(
                        color: HomeView.gold.withOpacity(0.85),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Rp ${_formatRp(order.totalPrice)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: HomeView.navy,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PaymentBadge(order: order),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  color: Colors.grey.shade400, size: 20),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRp(double amount) {
    final s = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
// ... (_PaymentBadge dan _EmptyState tetap sama) ...
class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final isPaid = order.isPaidOff;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPaid
            ? '✓ LUNAS'
            : 'DP Rp ${_mini(order.dpAmount)}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isPaid ? Colors.green.shade700 : Colors.amber.shade800,
        ),
      ),
    );
  }

  String _mini(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Belum ada order',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER FORM DIALOG (UPDATED)
// ─────────────────────────────────────────────────────────────────────────────

class _OrderFormDialog extends StatefulWidget {
  const _OrderFormDialog({
    required this.date,
    required this.controller,
    required this.onSaved,
    this.existingOrder,
  });

  final DateTime date;
  final HomeController controller;
  final VoidCallback onSaved;
  final OrderModel? existingOrder;

  @override
  State<_OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderFormDialogState extends State<_OrderFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _dpCtrl;
  late final TextEditingController _addonsCtrl;
  
  // ADDED: State untuk tanggal masuk
  late DateTime _selectedEntryDate;

  bool get _isEdit => widget.existingOrder != null;

  @override
  void initState() {
    super.initState();
    final o = widget.existingOrder;
    _nameCtrl = TextEditingController(text: o?.customerName ?? '');
    _typeCtrl = TextEditingController(text: o?.clothingType ?? '');
    _priceCtrl = TextEditingController(
        text: o != null ? o.totalPrice.toStringAsFixed(0) : '');
    _dpCtrl = TextEditingController(
        text: o != null ? o.dpAmount.toStringAsFixed(0) : '');
    _addonsCtrl = TextEditingController(text: o?.addons ?? '');
    
    // ADDED: Inisialisasi tanggal masuk
    // Jika edit, pakai tanggal yang ada. Jika baru, pakai hari ini.
    _selectedEntryDate = o?.entryDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _priceCtrl.dispose();
    _dpCtrl.dispose();
    _addonsCtrl.dispose();
    super.dispose();
  }
  
  // ADDED: Fungsi untuk menampilkan date picker
  Future<void> _pickEntryDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEntryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Bisa diubah
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: HomeView.navy,
              onPrimary: Colors.white,
              onSurface: HomeView.navy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedEntryDate) {
      setState(() {
        _selectedEntryDate = pickedDate;
      });
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final type = _typeCtrl.text.trim();

    if (name.isEmpty || type.isEmpty) {
      Get.snackbar('Form Tidak Lengkap', 'Nama dan jenis baju harus diisi.');
      return;
    }

    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final dp = (double.tryParse(_dpCtrl.text) ?? 0.0).clamp(0.0, price);

    final newOrder = OrderModel(
      id: widget.existingOrder?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: name,
      clothingType: type,
      totalPrice: price,
      dpAmount: dp,
      addons: _addonsCtrl.text.trim(),
      deadline: widget.date,
      entryDate: _selectedEntryDate, // UPDATED: Gunakan tanggal yang dipilih
    );

    if (_isEdit) {
      widget.controller.updateOrder(widget.date, newOrder);
    } else {
      widget.controller.addOrder(widget.date, newOrder);
    }

    Get.back();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HomeView.navy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                    color: HomeView.navy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(_isEdit ? 'Edit Order' : 'Order Baru'),
              ],
            ),
            const SizedBox(height: 4),
            Text('Deadline: ${widget.controller.formatDisplayDate(widget.date)}'),
            const SizedBox(height: 20),
            
            // ADDED: Input Tanggal Masuk
            _DatePickerField(
              label: 'Tanggal Masuk',
              selectedDate: _selectedEntryDate,
              onTap: _pickEntryDate,
            ),
            const SizedBox(height: 14),

            _FormField(controller: _nameCtrl, label: 'Nama Klien'),
            const SizedBox(height: 14),
            _FormField(controller: _typeCtrl, label: 'Jenis Baju'),
            const SizedBox(height: 14),
            _FormField(controller: _priceCtrl, label: 'Harga Total', keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _FormField(controller: _dpCtrl, label: 'Dibayar / DP', keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _FormField(controller: _addonsCtrl, label: 'Add-on (opsional)'),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: TextButton(onPressed: Get.back, child: const Text('Batal'))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: ElevatedButton(onPressed: _save, child: const Text('Simpan'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ADDED: Widget baru untuk field tanggal
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.selectedDate,
    required this.onTap,
  });

  final String label;
  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d MMMM yyyy', 'id_ID').format(selectedDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: HomeView.navy.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: HomeView.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: HomeView.navy.withOpacity(0.5), size: 20),
                const SizedBox(width: 12),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 14, color: HomeView.navy),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ... (_FormField dan sisa widget lainnya tetap sama) ...
class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: HomeView.navy),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: HomeView.navy.withOpacity(0.6), fontSize: 13),
      ),
    );
  }
}

class _YearlyStatsSheet extends StatelessWidget {
  const _YearlyStatsSheet({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final year = controller.currentYear.value;
      final stats = controller.getYearlyStats(year);

      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Laporan $year',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: HomeView.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ringkasan seluruh order sepanjang tahun',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _StatTile(
              icon: Icons.shopping_bag_outlined,
              label: 'Total Order',
              value: '${stats.totalOrders} baju',
              color: HomeView.navy,
            ),
            _StatTile(
              icon: Icons.check_circle_outline,
              label: 'Sudah Lunas',
              value: '${stats.paidOffCount} order',
              color: Colors.green.shade600,
            ),
            _StatTile(
              icon: Icons.pending_outlined,
              label: 'Masih DP / Belum Lunas',
              value: '${stats.pendingCount} order',
              color: Colors.amber.shade700,
            ),
            const Divider(height: 28, indent: 12, endIndent: 12),
            _StatTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total Nilai Proyek',
              value: 'Rp ${_rp(stats.totalRevenue)}',
              color: HomeView.gold,
              large: true,
            ),
            _StatTile(
              icon: Icons.monetization_on_outlined,
              label: 'Uang Diterima',
              value: 'Rp ${_rp(stats.totalCollected)}',
              color: Colors.green.shade600,
              large: true,
            ),
            _StatTile(
              icon: Icons.money_off_outlined,
              label: 'Sisa Piutang',
              value: 'Rp ${_rp(stats.totalReceivables)}',
              color: Colors.redAccent,
              large: true,
            ),
            if (stats.totalOrders > 0) ...[
              const SizedBox(height: 16),
              _ReceivablesBar(ratio: stats.receivablesRatio),
            ],
          ],
        ),
      );
    });
  }

  String _rp(double v) {
    final s = v.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
class _MonthlyStatsSheet extends StatelessWidget {
  const _MonthlyStatsSheet({
    required this.controller,
    required this.year,
    required this.month,
  });

  final HomeController controller;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.getMonthlyStats(year, month);
      final monthName = HomeController.monthNames[month - 1];

      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Laporan $monthName $year',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: HomeView.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ringkasan seluruh order di bulan ini',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _StatTile(
              icon: Icons.shopping_bag_outlined,
              label: 'Total Order',
              value: '${stats.totalOrders} baju',
              color: HomeView.navy,
            ),
            _StatTile(
              icon: Icons.check_circle_outline,
              label: 'Sudah Lunas',
              value: '${stats.paidOffCount} order',
              color: Colors.green.shade600,
            ),
            _StatTile(
              icon: Icons.pending_outlined,
              label: 'Masih DP / Belum Lunas',
              value: '${stats.pendingCount} order',
              color: Colors.amber.shade700,
            ),
            const Divider(height: 28, indent: 12, endIndent: 12),
            _StatTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total Nilai Proyek',
              value: 'Rp ${_rp(stats.totalRevenue)}',
              color: HomeView.gold,
              large: true,
            ),
            _StatTile(
              icon: Icons.monetization_on_outlined,
              label: 'Uang Diterima',
              value: 'Rp ${_rp(stats.totalCollected)}',
              color: Colors.green.shade600,
              large: true,
            ),
            _StatTile(
              icon: Icons.money_off_outlined,
              label: 'Sisa Piutang',
              value: 'Rp ${_rp(stats.totalReceivables)}',
              color: Colors.redAccent,
              large: true,
            ),
            if (stats.totalOrders > 0) ...[
              const SizedBox(height: 16),
              _ReceivablesBar(ratio: stats.receivablesRatio),
            ],
          ],
        ),
      );
    });
  }

  String _rp(double v) {
    final s = v.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: large ? 16 : 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _ReceivablesBar extends StatelessWidget {
  const _ReceivablesBar({required this.ratio});
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final collected = (1 - ratio).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progres Pembayaran',
          style: TextStyle(
              color: Colors.grey.shade500, fontSize: 12),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: collected,
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.green,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(collected * 100).toStringAsFixed(0)}% terbayar',
              style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              '${(ratio * 100).toStringAsFixed(0)}% piutang',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}