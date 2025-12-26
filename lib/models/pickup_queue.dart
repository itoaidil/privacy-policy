class PickupQueue {
  final int? id;
  final int travelId;
  final int bookingId;
  final String pickupLocation;
  final double pickupLatitude;
  final double pickupLongitude;
  final double? distanceFromDriver; // in kilometers
  final int queuePosition;
  final String status; // waiting, picking_up, completed
  final DateTime timestamp;

  // Additional customer info
  final String? customerName;
  final String? customerPhone;

  PickupQueue({
    this.id,
    required this.travelId,
    required this.bookingId,
    required this.pickupLocation,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.distanceFromDriver,
    required this.queuePosition,
    required this.status,
    required this.timestamp,
    this.customerName,
    this.customerPhone,
  });

  factory PickupQueue.fromJson(Map<String, dynamic> json) {
    return PickupQueue(
      id: json['id'],
      travelId: json['travel_id'],
      bookingId: json['booking_id'],
      pickupLocation: json['pickup_location'],
      pickupLatitude: double.parse(json['pickup_latitude'].toString()),
      pickupLongitude: double.parse(json['pickup_longitude'].toString()),
      distanceFromDriver: json['distance_from_driver'] != null
          ? double.parse(json['distance_from_driver'].toString())
          : null,
      queuePosition: json['queue_position'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'travel_id': travelId,
      'booking_id': bookingId,
      'pickup_location': pickupLocation,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'distance_from_driver': distanceFromDriver,
      'queue_position': queuePosition,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'waiting':
        return 'Menunggu';
      case 'picking_up':
        return 'Sedang Dijemput';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  String get distanceDisplay {
    if (distanceFromDriver == null) return '-';
    if (distanceFromDriver! < 1) {
      return '${(distanceFromDriver! * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceFromDriver!.toStringAsFixed(1)} km';
  }
}
