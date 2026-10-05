import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerEntry {
  final String name;
  final DateTime time;
  const PrayerEntry(this.name, this.time);
}

/// Location + qiblah bearing + prayer times + live compass heading.
class QiblahProvider extends ChangeNotifier {
  Position? _position;
  Position? get position => _position;

  double? _heading;
  double? get heading => _heading;

  String _locationLabel = 'Lokasi belum diatur';
  String get locationLabel => _locationLabel;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<PrayerEntry> _prayers = const [];
  List<PrayerEntry> get prayers => _prayers;

  PrayerEntry? _next;
  PrayerEntry? get next => _next;

  String _method = 'kemenag';
  String get method => _method;

  StreamSubscription<CompassEvent>? _compassSub;

  static const _kaabaLat = 21.4225;
  static const _kaabaLng = 39.8262;

  /// Great-circle bearing from the user to the Ka'bah, degrees from true north.
  double? get qiblahBearing {
    final p = _position;
    if (p == null) return null;
    return _bearing(p.latitude, p.longitude, _kaabaLat, _kaabaLng);
  }

  /// Device rotation so the qiblah arrow points correctly on screen.
  /// heading = compass direction the top of the phone points at.
  double? get qiblahRotation {
    final b = qiblahBearing;
    final h = _heading;
    if (b == null || h == null) return null;
    return (b - h) * math.pi / 180;
  }

  double get qiblahDistanceKm {
    final p = _position;
    if (p == null) return 0;
    return Geolocator.distanceBetween(p.latitude, p.longitude, _kaabaLat, _kaabaLng) / 1000;
  }

  bool get isAligned {
    final b = qiblahBearing;
    final h = _heading;
    if (b == null || h == null) return false;
    final d = (b - h).abs() % 360;
    final diff = d > 180 ? 360 - d : d;
    return diff < 5;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _method = prefs.getString('prayerMethod') ?? 'kemenag';
    final lat = prefs.getDouble('lat');
    final lng = prefs.getDouble('lng');
    if (lat != null && lng != null) {
      _locationLabel = prefs.getString('locLabel') ?? 'Lokasi tersimpan';
      _position = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _computePrayers();
      notifyListeners();
    }
    _startCompass();
  }

  void _startCompass() {
    _compassSub?.cancel();
    // flutter_compass has no web implementation, so listening on web throws a
    // MissingPluginException on every event. The qiblah bearing still works
    // from the location; only the live "which way is the phone facing" arrow
    // is unavailable in a browser.
    if (kIsWeb) return;
    _compassSub = FlutterCompass.events?.listen((e) {
      if (e.heading != null) {
        _heading = e.heading;
        notifyListeners();
      }
    });
  }

  Future<bool> refreshLocation({bool useGps = true}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _error = 'Izin lokasi ditolak. Aktifkan di pengaturan untuk qiblah akurat.';
        _loading = false;
        notifyListeners();
        return false;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
      await _setPosition(p);
      return true;
    } catch (e) {
      _error = 'Gagal mendapatkan lokasi: ${e.toString().split('\n').first}';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setManualLocation(double lat, double lng, String label) async {
    final p = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    await _setPosition(p, label: label);
  }

  Future<void> _setPosition(Position p, {String? label}) async {
    _position = p;
    _locationLabel = label ?? 'Lokasi saat ini';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lat', p.latitude);
    await prefs.setDouble('lng', p.longitude);
    await prefs.setString('locLabel', _locationLabel);
    _computePrayers();
    notifyListeners();
  }

  Future<void> setMethod(String m) async {
    _method = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayerMethod', m);
    _computePrayers();
    notifyListeners();
  }

  void _computePrayers() {
    final p = _position;
    if (p == null) return;
    final params = switch (_method) {
      'mwl' => CalculationMethod.muslim_world_league.getParameters(),
      'egypt' => CalculationMethod.egyptian.getParameters(),
      'makkah' => CalculationMethod.umm_al_qura.getParameters(),
      'karachi' => CalculationMethod.karachi.getParameters(),
      'isna' => CalculationMethod.north_america.getParameters(),
      _ => CalculationMethod.singapore.getParameters(),
    };
    params.madhab = Madhab.shafi;
    final coords = Coordinates(p.latitude, p.longitude);
    final date = DateComponents.from(DateTime.now());
    final pt = PrayerTimes(coords, date, params);
    _prayers = [
      PrayerEntry('Imsak', pt.fajr.subtract(const Duration(minutes: 10))),
      PrayerEntry('Subuh', pt.fajr),
      PrayerEntry('Terbit', pt.sunrise),
      PrayerEntry('Dzuhur', pt.dhuhr),
      PrayerEntry('Ashar', pt.asr),
      PrayerEntry('Maghrib', pt.maghrib),
      PrayerEntry('Isya', pt.isha),
    ];
    final now = DateTime.now();
    _next = _prayers.where((e) => e.time.isAfter(now)).cast<PrayerEntry?>().firstWhere((e) => true, orElse: () => null);
    _next ??= PrayerEntry('Subuh', pt.fajr.add(const Duration(days: 1)));
  }

  static double _bearing(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dLambda = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    final theta = math.atan2(y, x);
    return (theta * 180 / math.pi + 360) % 360;
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }
}
