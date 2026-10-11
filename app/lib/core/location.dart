import 'districts.dart';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'config.dart';

enum LocationAccess { granted, denied, deniedForever, serviceOff }

class Fix {
  const Fix(this.position, this.accuracy, {this.mocked = false, this.substituted = false});
  final LatLng position;
  final double accuracy;

  /// Position came from a mock-location app (Android) or was simulated by software (iOS).
  /// Such reports are rejected — except in demo builds, so simulators can be used for testing.
  final bool mocked;

  /// Demo mode only: the device is outside Bangladesh, so we use central Dhaka instead.
  final bool substituted;
}

class Place {
  const Place({this.area, this.city, this.address, this.districtId});
  final String? area;
  final String? city;
  final String? address;

  /// One of [districtIds] when the geocoder's district name was recognised.
  final String? districtId;
}

class LocationService {
  const LocationService();

  static const dhaka = LatLng(23.7808, 90.4000);

  static bool _inBangladesh(LatLng p) =>
      p.latitude > 20.5 && p.latitude < 26.7 && p.longitude > 88.0 && p.longitude < 92.7;

  Future<LocationAccess> check() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    return _map(await Geolocator.checkPermission());
  }

  Future<LocationAccess> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return _map(p);
  }

  Future<bool> openSettings(LocationAccess access) =>
      access == LocationAccess.serviceOff ? Geolocator.openLocationSettings() : Geolocator.openAppSettings();

  static LocationAccess _map(LocationPermission p) => switch (p) {
    LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
    LocationPermission.deniedForever => LocationAccess.deniedForever,
    _ => LocationAccess.denied,
  };

  /// A fresh, high-accuracy fix (used when posting a report).
  Future<Fix> current() async {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
    );
    return _fix(p);
  }

  /// Fast, possibly cached fix (used for centring the feed and map).
  Future<Fix> approximate() async {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null && DateTime.now().difference(last.timestamp) < const Duration(minutes: 10)) return _fix(last);
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 12)),
    );
    return _fix(p);
  }

  Fix _fix(Position p) {
    final point = LatLng(p.latitude, p.longitude);
    if (AppConfig.isDemo && !_inBangladesh(point)) {
      return Fix(dhaka, p.accuracy, substituted: true);
    }
    return Fix(point, p.accuracy, mocked: p.isMocked && !AppConfig.isDemo);
  }

  Future<Place> describe(LatLng p) async {
    try {
      final marks = await Geocoding().placemarkFromCoordinates(p.latitude, p.longitude);
      if (marks.isEmpty) return const Place();
      final m = marks.first;
      String? clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
      final area = clean(m.subLocality) ?? clean(m.locality) ?? clean(m.subAdministrativeArea);
      final city = clean(m.locality) != area ? clean(m.locality) : clean(m.administrativeArea);
      final address = [clean(m.street), area, city].whereType<String>().toSet().join(', ');
      final district = districtIdFromName(clean(m.subAdministrativeArea)) ?? districtIdFromName(clean(m.locality));
      return Place(area: area, city: city, address: address.isEmpty ? null : address, districtId: district);
    } on Exception {
      return const Place(); // Geocoding is best-effort; the coordinates are what matter.
    }
  }
}
