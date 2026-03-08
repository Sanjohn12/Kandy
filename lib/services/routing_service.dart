import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

enum TravelMode { walking, cycling, driving }

class RouteData {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;
  final double? costCar;
  final double? costBike;
  final double? costTuk;
  final double? co2SavedKg;

  RouteData({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    this.costCar,
    this.costBike,
    this.costTuk,
    this.co2SavedKg,
  });
}

class RoutingService {
  final String _apiKey =
      '5b3ce3597851110001cf6248aca8bc548cbb17d7525209d8e040a0b603f8f10ba4e7aa772150c1c0';
  final String _baseUrl = 'https://api.openrouteservice.org/v2/directions';

  // --- Travel Cost Estimation Constants (LKR) ---
  static const double fuelPricePerLiter = 370.0; // Sri Lanka Petrol 92 Octane
  static const double mileageCar = 15.0; // km/L
  static const double mileageBike = 40.0; // km/L
  static const double mileageTuk = 25.0; // km/L
  static const double co2EmissionPerKm =
      0.15; // kg of CO2 per km for a standard car

  String _getProfile(TravelMode mode) {
    switch (mode) {
      case TravelMode.walking:
        return 'foot-walking';
      case TravelMode.cycling:
        return 'cycling-regular';
      case TravelMode.driving:
        return 'driving-car';
    }
  }

  Future<RouteData?> fetchRoute(
      LatLng start, LatLng end, TravelMode mode) async {
    final profile = _getProfile(mode);

    // Using V2 GET endpoint as it is more stable and verified working for long distances
    String urlString = '$_baseUrl/$profile?'
        'api_key=$_apiKey&'
        'start=${start.longitude},${start.latitude}&'
        'end=${end.longitude},${end.latitude}&'
        'radiuses=1000,1000'; // Snap to nearest road within 1km

    // CORS bypass for Web development. Not needed for Mobile apps (Android/iOS).
    if (kIsWeb) {
      urlString = 'https://cors-anywhere.herokuapp.com/' + urlString;
    }

    final url = Uri.parse(urlString);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] == null || (data['features'] as List).isEmpty) {
          debugPrint(
              'ORS Warning: No features found for $profile. This usually means no road connection exists between these points.');
          return null;
        }

        final feature = data['features'][0];
        final geometry = feature['geometry']['coordinates'] as List;
        final properties = feature['properties']['summary'];
        final distanceKm = (properties['distance'] as num).toDouble() / 1000.0;

        if (geometry.isEmpty) {
          debugPrint('ORS Warning: Geometry is empty');
          return null;
        }

        final List<LatLng> points = geometry.map((coord) {
          return LatLng(coord[1] as double, coord[0] as double);
        }).toList();

        double? costCar;
        double? costBike;
        double? costTuk;
        double? co2SavedKg;

        if (mode == TravelMode.driving) {
          costCar = (distanceKm / mileageCar) * fuelPricePerLiter;
          costBike = (distanceKm / mileageBike) * fuelPricePerLiter;
          costTuk = (distanceKm / mileageTuk) * fuelPricePerLiter;
        } else {
          // Walking or Cycling saves CO2 compared to driving a car
          co2SavedKg = distanceKm * co2EmissionPerKm;
        }

        return RouteData(
          points: points,
          distanceKm: distanceKm,
          durationMinutes: (properties['duration'] as num).toDouble() / 60.0,
          costCar: costCar,
          costBike: costBike,
          costTuk: costTuk,
          co2SavedKg: co2SavedKg,
        );
      } else {
        final errorMsg =
            'ORS API error: ${response.statusCode} - ${response.body}';
        debugPrint(errorMsg);
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching ORS route: $e');
      return null;
    }
  }
}
