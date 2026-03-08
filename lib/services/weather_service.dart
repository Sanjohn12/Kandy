import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final int weatherCode;

  WeatherData({required this.temperature, required this.weatherCode});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final currentValues = json['current'];
    return WeatherData(
      temperature: (currentValues['temperature_2m'] as num).toDouble(),
      weatherCode: currentValues['weather_code'] as int,
    );
  }
}

class ForecastDay {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;

  ForecastDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });
}

class WeatherService {
  // Open-Meteo API (Free, no key required)
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetchWeather(double lat, double lng) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lng&current=temperature_2m,weather_code',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  Future<List<ForecastDay>> fetchWeeklyForecast(double lat, double lng) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lng&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];
        final times = daily['time'] as List;
        final codes = daily['weather_code'] as List;
        final maxs = daily['temperature_2m_max'] as List;
        final mins = daily['temperature_2m_min'] as List;

        return List.generate(times.length, (i) {
          return ForecastDay(
            date: DateTime.parse(times[i]),
            weatherCode: codes[i] as int,
            maxTemp: (maxs[i] as num).toDouble(),
            minTemp: (mins[i] as num).toDouble(),
          );
        });
      } else {
        throw Exception('Failed to load forecast');
      }
    } catch (e) {
      throw Exception('Error fetching forecast: $e');
    }
  }

  Future<double?> fetchElevation(double lat, double lng) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/elevation?latitude=$lat&longitude=$lng',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['elevation'] != null &&
            (data['elevation'] as List).isNotEmpty) {
          return (data['elevation'][0] as num).toDouble();
        }
        return null;
      } else {
        debugPrint('Elevation API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching elevation: $e');
      return null;
    }
  }
}
