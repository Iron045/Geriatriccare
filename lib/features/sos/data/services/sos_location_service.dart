import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum SosLocationFailure { serviceDisabled, denied, deniedForever, unavailable }

class SosLocationResult {
  const SosLocationResult._({this.position, this.failure});

  const SosLocationResult.available(Position position)
      : this._(position: position);

  const SosLocationResult.unavailable(SosLocationFailure failure)
      : this._(failure: failure);

  final Position? position;
  final SosLocationFailure? failure;

  bool get hasLocation => position != null;
}

abstract final class SosLocationService {
  static Future<SosLocationResult> captureCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const SosLocationResult.unavailable(
          SosLocationFailure.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const SosLocationResult.unavailable(
          SosLocationFailure.deniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        return const SosLocationResult.unavailable(SosLocationFailure.denied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 11));
      return SosLocationResult.available(position);
    } on TimeoutException {
      return const SosLocationResult.unavailable(
        SosLocationFailure.unavailable,
      );
    } catch (_) {
      return const SosLocationResult.unavailable(
        SosLocationFailure.unavailable,
      );
    }
  }
}
