class ScheduleModel {
  final int travelId;
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final double price;
  final String travelStatus;
  final int vehicleId;
  final String vehicleName;
  final String licensePlate;
  final int capacity;
  final String brand;
  final String model;
  final int year;
  final int poId;
  final String poName;
  final String companyCode;
  final int bookedSeats;
  final int availableSeats;

  ScheduleModel({
    required this.travelId,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.travelStatus,
    required this.vehicleId,
    required this.vehicleName,
    required this.licensePlate,
    required this.capacity,
    required this.brand,
    required this.model,
    required this.year,
    required this.poId,
    required this.poName,
    required this.companyCode,
    required this.bookedSeats,
    required this.availableSeats,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      travelId: json['travel_id'] ?? 0,
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      departureTime: json['departure_time'] ?? '',
      arrivalTime: json['arrival_time'] ?? '',
      price: _parsePrice(json['price']),
      travelStatus: json['travel_status'] ?? '',
      vehicleId: json['vehicle_id'] ?? 0,
      vehicleName: json['vehicle_name'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      capacity: json['capacity'] ?? 0,
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 0,
      poId: json['po_id'] ?? 0,
      poName: json['po_name'] ?? '',
      companyCode: json['company_code'] ?? '',
      bookedSeats: json['booked_seats'] ?? 0,
      availableSeats: json['available_seats'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'travel_id': travelId,
      'origin': origin,
      'destination': destination,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'price': price,
      'travel_status': travelStatus,
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'license_plate': licensePlate,
      'capacity': capacity,
      'brand': brand,
      'model': model,
      'year': year,
      'po_id': poId,
      'po_name': poName,
      'company_code': companyCode,
      'booked_seats': bookedSeats,
      'available_seats': availableSeats,
    };
  }

  // Helper method to format time (remove date, keep only time)
  String get formattedDepartureTime {
    try {
      // departureTime format: "2025-11-16T06:07:00.000Z"
      if (departureTime.contains('T')) {
        final timePart = departureTime.split('T')[1];
        final parts = timePart.split(':');
        return '${parts[0]}:${parts[1]}';
      }
      // fallback if format is different
      final parts = departureTime.split(':');
      return '${parts[0]}:${parts[1]}';
    } catch (e) {
      return departureTime;
    }
  }

  String get formattedArrivalTime {
    try {
      // If arrivalTime is empty, return dash
      if (arrivalTime.isEmpty) {
        return '-';
      }
      // arrivalTime format: "2025-11-16T08:30:00.000Z"
      if (arrivalTime.contains('T')) {
        final timePart = arrivalTime.split('T')[1];
        final parts = timePart.split(':');
        return '${parts[0]}:${parts[1]}';
      }
      // fallback if format is different
      final parts = arrivalTime.split(':');
      return '${parts[0]}:${parts[1]}';
    } catch (e) {
      return arrivalTime;
    }
  }

  // Calculate trip duration
  String get duration {
    try {
      final depParts = departureTime.split(':');
      final arrParts = arrivalTime.split(':');

      final depMinutes = int.parse(depParts[0]) * 60 + int.parse(depParts[1]);
      final arrMinutes = int.parse(arrParts[0]) * 60 + int.parse(arrParts[1]);

      int diff = arrMinutes - depMinutes;
      if (diff < 0) diff += 24 * 60; // Handle next day arrival

      final hours = diff ~/ 60;
      final minutes = diff % 60;

      return '${hours}j ${minutes}m';
    } catch (e) {
      return '-';
    }
  }

  // Get vehicle info string
  String get vehicleInfo {
    return '$brand $model ($year)';
  }

  // Parse price from string or number
  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }
}
