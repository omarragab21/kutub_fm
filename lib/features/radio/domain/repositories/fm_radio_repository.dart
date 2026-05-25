import '../fm_station.dart';

abstract class FmRadioRepository {
  Future<List<FmStation>> getStations({required bool quranOnly});
}
