class WeatherCondition {
  final int? id;
  final double latitude;
  final double longitude;
  final String location;
  final double temperature;
  final String weatherMain; // Clear, Clouds, Rain, etc.
  final String weatherDescription;
  final double? windSpeed;
  final int? humidity;
  final DateTime timestamp;

  WeatherCondition({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.temperature,
    required this.weatherMain,
    required this.weatherDescription,
    this.windSpeed,
    this.humidity,
    required this.timestamp,
  });

  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      id: json['id'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      location: json['location'],
      temperature: double.parse(json['temperature'].toString()),
      weatherMain: json['weather_main'],
      weatherDescription: json['weather_description'],
      windSpeed: json['wind_speed'] != null
          ? double.parse(json['wind_speed'].toString())
          : null,
      humidity: json['humidity'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'temperature': temperature,
      'weather_main': weatherMain,
      'weather_description': weatherDescription,
      'wind_speed': windSpeed,
      'humidity': humidity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get temperatureDisplay => '${temperature.toStringAsFixed(1)}°C';

  String get weatherIcon {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  bool get isDangerous {
    return weatherMain.toLowerCase() == 'thunderstorm' ||
        weatherMain.toLowerCase() == 'snow' ||
        (windSpeed != null && windSpeed! > 50);
  }
}
