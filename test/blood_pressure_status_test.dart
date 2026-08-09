import 'package:flutter_test/flutter_test.dart';
import 'package:geriatriccare/features/health/domain/entities/blood_pressure_status.dart';

void main() {
  group('classifyBloodPressure', () {
    test('LOW has priority after crisis', () {
      expect(classifyBloodPressure(89, 70).code, BloodPressureStatusCode.low);
      expect(classifyBloodPressure(110, 59).code, BloodPressureStatusCode.low);
    });

    test('classifies optimal and normal boundaries', () {
      expect(
        classifyBloodPressure(119, 79).code,
        BloodPressureStatusCode.optimal,
      );
      expect(
        classifyBloodPressure(120, 79).code,
        BloodPressureStatusCode.normal,
      );
      expect(
        classifyBloodPressure(119, 80).code,
        BloodPressureStatusCode.normal,
      );
    });

    test('uses the higher rising category when values differ', () {
      expect(
        classifyBloodPressure(130, 82).code,
        BloodPressureStatusCode.rising,
      );
      expect(
        classifyBloodPressure(125, 85).code,
        BloodPressureStatusCode.rising,
      );
    });

    test('classifies high and crisis readings', () {
      expect(classifyBloodPressure(140, 80).code, BloodPressureStatusCode.high);
      expect(
        classifyBloodPressure(180, 120).code,
        BloodPressureStatusCode.high,
      );
      expect(
        classifyBloodPressure(181, 80).code,
        BloodPressureStatusCode.crisis,
      );
      expect(
        classifyBloodPressure(150, 121).code,
        BloodPressureStatusCode.crisis,
      );
    });
  });
}
