class TravelTracking {
  final int? id;
  final int travelId;
  final double? latitude;
  final double? longitude;
  final String status; // on_the_way, arrived, picked_up, completed
  final String? notes;
  final DateTime timestamp;

  TravelTracking({
    this.id,
    required this.travelId,
    this.latitude,
    this.longitude,
    required this.status,
    this.notes,
    required this.timestamp,
  });

  factory TravelTracking.fromJson(Map<String, dynamic> json) {
    return TravelTracking(
      id: json['id'],
      travelId: json['travel_id'],
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      status: json['status'],
      notes: json['notes'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'travel_id': travelId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'on_the_way':
        return 'Dalam Perjalanan';
      case 'arrived':
        return 'Sudah Tiba di Lokasi';
      case 'picked_up':
        return 'Penumpang Sudah Dijemput';
      case 'completed':
        return 'Perjalanan Selesai';
      default:
        return status;
    }
  }
}
