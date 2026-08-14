import '../entities/elder_location.dart';

abstract interface class ElderLocationRepository {
  Stream<ElderLocation?> watchLocation(String elderId);

  Future<void> saveLocation(ElderLocation location);
}
