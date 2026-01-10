import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Dashboard',
      theme: ThemeData.dark(),
      home: const WeatherDashboard(),
    );
  }
}

class WeatherData {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;

  const WeatherData({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current_weather'] as Map<String, dynamic>;
    return WeatherData(
      temperature: (current['temperature'] as num).toDouble(),
      windSpeed: (current['windspeed'] as num).toDouble(),
      weatherCode: current['weathercode'] as int,
      isDay: current['is_day'] == 1,
    );
  }
}

class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({super.key});

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard> {
  DateTime _currentTime = DateTime.now();
  WeatherData? _weatherData;
  String? _weatherError;
  bool _isLoadingWeather = true;

  Timer? _clockTimer;
  Timer? _weatherTimer;

  @override
  void initState() {
    super.initState();
    _startClock();
    _fetchWeather();
    _startWeatherTimer();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _weatherTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  void _startWeatherTimer() {
    _weatherTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _fetchWeather();
    });
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });

    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=54.629&longitude=39.742&current_weather=true',
      );
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        final weatherData = WeatherData.fromJson(jsonData);

        setState(() {
          _weatherData = weatherData;
          _isLoadingWeather = false;
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        _weatherError = 'Failed to load weather';
        _isLoadingWeather = false;
      });
    }
  }

  String _formatTime() {
    return '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDate() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${_currentTime.day} ${months[_currentTime.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatDate(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoadingWeather)
                        const Text(
                          'Loading weather...',
                          style: TextStyle(color: Colors.grey, fontSize: 24),
                        )
                      else if (_weatherError != null)
                        Text(
                          _weatherError!,
                          style: const TextStyle(color: Colors.grey, fontSize: 24),
                        )
                      else if (_weatherData != null)
                        Column(
                          children: [
                            Text(
                              '${_weatherData!.temperature.round()}°C',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Wind: ${_weatherData!.windSpeed.toStringAsFixed(1)} km/h · Code: ${_weatherData!.weatherCode} · ${_weatherData!.isDay ? 'Day' : 'Night'}',
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 5,
            left: 5,
            child: IconButton(
              onPressed: _fetchWeather,
              icon: const Icon(Icons.refresh),
              color: Colors.grey,
              iconSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}
