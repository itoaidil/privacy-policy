class RouteInfo {
  final double distance; // in kilometers
  final int duration; // in minutes
  final List<LatLng> polylinePoints;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.polylinePoints,
  });

  String get distanceDisplay {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  String get durationDisplay {
    if (duration < 60) {
      return '$duration mnt';
    }
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    return '$hours jam $minutes mnt';
  }

  String get etaDisplay {
    final now = DateTime.now();
    final eta = now.add(Duration(minutes: duration));
    final hour = eta.hour.toString().padLeft(2, '0');
    final minute = eta.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
