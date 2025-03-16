import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import 'map_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _weatherService = WeatherService();
  late Future<List<Weather>> _weatherFuture;
  double _progress = 0.0;
  String _loadingMessage = "Nous téléchargeons les données...";
  bool _dataLoaded = false;
  bool _showRestartButton = false;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() async {
    setState(() {
      _progress = 0.0;
      _dataLoaded = false;
      _showRestartButton = false;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _progress += 10;
        _loadingMessage = _getLoadingMessage(i);
      });
    }

    try {
      _weatherFuture = _fetchWeatherForCities();
      setState(() {
        _dataLoaded = true;
        _showRestartButton = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : Impossible de récupérer les données météo."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getLoadingMessage(int step) {
    if (step < 4) return "Nous téléchargeons les données...";
    if (step < 7) return "C'est presque fini...";
    return "Plus que quelques secondes avant d’avoir le résultat...";
  }

  Future<List<Weather>> _fetchWeatherForCities() async {
    try {
      return await _weatherService.getWeatherForMultipleCities();
    } catch (e) {
      throw Exception("Erreur lors de la récupération des données météo : $e");
    }
  }

  void _openMap(String city, double lat, double lon) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              MapScreen(latitude: lat, longitude: lon, cityName: city)),
    );
  }

  String _getAnimationForCondition(String condition) {
    switch (condition.toLowerCase()) {
      case "clear":
        return 'assets/sunny.json';
      case "clouds":
        return 'assets/cloudy.json';
      case "rain":
        return 'assets/rainy.json';
      case "thunderstorm":
        return 'assets/thunderstorm.json';
      case "snow":
        return 'assets/snow.json';
      default:
        return 'assets/cloud.json';
    }
  }

  Widget _loadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/loading.json', width: 150, height: 150),
        const SizedBox(height: 20),
        Text(
          _loadingMessage,
          style: const TextStyle(fontSize: 18, color: Colors.blue),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FAProgressBar(
          currentValue: _progress,
          displayText: '%',
          size: 20,
          progressColor: Colors.blue,
          backgroundColor: Colors.grey[300]!,
          animatedDuration: const Duration(milliseconds: 500),
        ),
        const SizedBox(height: 20),
        _showRestartButton
            ? ElevatedButton(
                onPressed: _startLoading,
                child: const Text("Recommencer"),
              )
            : const SizedBox(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Météo")),
      body: Center(
        child: _dataLoaded
            ? FutureBuilder<List<Weather>>(
                future: _weatherFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Erreur : ${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.red),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _startLoading,
                            child: const Text("Réessayer"),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasData) {
                    List<Weather> weatherList = snapshot.data!;
                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(
                                    label: Text("Ville",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text("Température",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text("Condition",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text("Animation",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text("Carte",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                              rows: weatherList.map((weather) {
                                return DataRow(cells: [
                                  DataCell(Text(weather.cityName)),
                                  DataCell(Text("${weather.temperature}°C")),
                                  DataCell(Text(weather.condition)),
                                  DataCell(
                                    SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: Lottie.asset(
                                        _getAnimationForCondition(
                                            weather.condition),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.map,
                                          color: Colors.blue),
                                      onPressed: () => _openMap(
                                        weather.cityName,
                                        weather.latitude,
                                        weather.longitude,
                                      ),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _startLoading,
                          child: const Text("Recommencer"),
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              )
            : _loadingIndicator(),
      ),
    );
  }
}
