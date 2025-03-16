class Weather {
  final String cityName;
  final String condition;
  final double temperature;
  final double latitude;
  final double longitude;

  Weather({
    required this.cityName,
    required this.condition,
    required this.temperature,
    required this.latitude,
    required this.longitude,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      condition: json['weather'][0]['main'],
      latitude: json['coord']['lat'].toDouble(),
      longitude: json['coord']['lon'].toDouble(),
    );
  }
}
