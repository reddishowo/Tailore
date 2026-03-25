// File: /lib/app/data/models/order_model.dart

class OrderModel {
  final String id;
  final String customerName;
  final String clothingType;
  final double totalPrice;
  final double dpAmount;
  final String addons;
  final DateTime deadline;
  final DateTime entryDate; // ADDED: Tanggal order masuk

  const OrderModel({
    required this.id,
    required this.customerName,
    required this.clothingType,
    this.totalPrice = 0.0,
    this.dpAmount = 0.0,
    this.addons = '',
    required this.deadline,
    required this.entryDate, // ADDED
  });

  // ─── Computed Properties ───────────────────────────────────────────────────

  bool get isPaidOff => dpAmount >= totalPrice && totalPrice > 0;
  double get remainingDebt => (totalPrice - dpAmount).clamp(0.0, double.infinity);
  double get paymentProgress =>
      totalPrice > 0 ? (dpAmount / totalPrice).clamp(0.0, 1.0) : 0.0;

  // ─── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'clothingType': clothingType,
        'totalPrice': totalPrice,
        'dpAmount': dpAmount,
        'addons': addons,
        'deadline': deadline.toIso8601String(),
        'entryDate': entryDate.toIso8601String(), // ADDED
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        customerName: json['customerName'] as String,
        clothingType: json['clothingType'] as String,
        totalPrice: (json['totalPrice'] as num).toDouble(),
        dpAmount: (json['dpAmount'] as num).toDouble(),
        addons: json['addons'] as String? ?? '',
        deadline: DateTime.parse(json['deadline'] as String),
        // ADDED: Fallback ke deadline jika data lama tidak punya entryDate
        entryDate: DateTime.parse(json['entryDate'] ?? json['deadline'] as String),
      );

  // ─── Immutable Update ──────────────────────────────────────────────────────

  OrderModel copyWith({
    String? id,
    String? customerName,
    String? clothingType,
    double? totalPrice,
    double? dpAmount,
    String? addons,
    DateTime? deadline,
    DateTime? entryDate, // ADDED
  }) =>
      OrderModel(
        id: id ?? this.id,
        customerName: customerName ?? this.customerName,
        clothingType: clothingType ?? this.clothingType,
        totalPrice: totalPrice ?? this.totalPrice,
        dpAmount: dpAmount ?? this.dpAmount,
        addons: addons ?? this.addons,
        deadline: deadline ?? this.deadline,
        entryDate: entryDate ?? this.entryDate, // ADDED
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OrderModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OrderModel(id: $id, customer: $customerName, type: $clothingType)';
}

// ... sisa file DailySchedule dan ScheduleStats tidak berubah ...
class DailySchedule {
  final DateTime date;
  final List<OrderModel> orders;
  final int maxCapacity;

  const DailySchedule({
    required this.date,
    required this.orders,
    this.maxCapacity = 3,
  });

  // ─── Computed Properties ───────────────────────────────────────────────────

  /// 0.0 = kosong, 1.0 = penuh
  double get capacityPercentage {
    if (orders.isEmpty) return 0.0;
    return (orders.length / maxCapacity).clamp(0.0, 1.0);
  }

  bool get isFull => orders.length >= maxCapacity;

  int get remainingSlots => (maxCapacity - orders.length).clamp(0, maxCapacity);

  double get totalRevenue =>
      orders.fold(0.0, (sum, o) => sum + o.totalPrice);

  double get totalCollected =>
      orders.fold(0.0, (sum, o) => sum + o.dpAmount);

  double get totalReceivables =>
      orders.fold(0.0, (sum, o) => sum + o.remainingDebt);

  // ─── Immutable Helpers ─────────────────────────────────────────────────────

  DailySchedule withAddedOrder(OrderModel order) => DailySchedule(
        date: date,
        orders: [...orders, order],
        maxCapacity: maxCapacity,
      );

  DailySchedule withUpdatedOrder(OrderModel updated) => DailySchedule(
        date: date,
        orders: orders.map((o) => o.id == updated.id ? updated : o).toList(),
        maxCapacity: maxCapacity,
      );

  DailySchedule withRemovedOrder(String orderId) => DailySchedule(
        date: date,
        orders: orders.where((o) => o.id != orderId).toList(),
        maxCapacity: maxCapacity,
      );

  // ─── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'maxCapacity': maxCapacity,
        'orders': orders.map((o) => o.toJson()).toList(),
      };

  factory DailySchedule.fromJson(Map<String, dynamic> json) => DailySchedule(
        date: DateTime.parse(json['date'] as String),
        maxCapacity: json['maxCapacity'] as int? ?? 3,
        orders: (json['orders'] as List<dynamic>)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ScheduleStats {
  final int totalOrders;
  final double totalRevenue;
  final double totalCollected;
  final double totalReceivables;
  final int paidOffCount;
  final int pendingCount;

  const ScheduleStats({
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.totalCollected = 0,
    this.totalReceivables = 0,
    this.paidOffCount = 0,
    this.pendingCount = 0,
  });

  double get receivablesRatio =>
      totalRevenue > 0 ? totalReceivables / totalRevenue : 0.0;

  ScheduleStats operator +(ScheduleStats other) => ScheduleStats(
        totalOrders: totalOrders + other.totalOrders,
        totalRevenue: totalRevenue + other.totalRevenue,
        totalCollected: totalCollected + other.totalCollected,
        totalReceivables: totalReceivables + other.totalReceivables,
        paidOffCount: paidOffCount + other.paidOffCount,
        pendingCount: pendingCount + other.pendingCount,
      );
}