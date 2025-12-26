class DriverLocation {
  final int? id;
  final int driverId;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final bool isActive;

  DriverLocation({
    this.id,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    this.isActive = true,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      id: json['id'],
      driverId: json['driver_id'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      address: json['address'],
      timestamp: DateTime.parse(json['updated_at'] ??
          json['timestamp'] ??
          DateTime.now().toIso8601String()),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'is_active': isActive,
    };
  }
}
