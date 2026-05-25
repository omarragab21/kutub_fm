import '../../domain/fm_station.dart';
import '../../domain/repositories/fm_radio_repository.dart';
import '../datasources/firebase_fm_radio_data_source.dart';
import '../models/fm_station_model.dart';

class FmRadioRepositoryImpl implements FmRadioRepository {
  FmRadioRepositoryImpl({FirebaseFmRadioDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseFmRadioDataSource();

  final FirebaseFmRadioDataSource _dataSource;

  @override
  Future<List<FmStation>> getStations({required bool quranOnly}) async {
    final stations = await _dataSource.fetchStations();
    final filtered = quranOnly
        ? stations.where((station) => station.isQuranStation)
        : stations;

    final sorted = filtered.toList()
      ..sort((a, b) {
        final orderCompare = _sortOrder(a).compareTo(_sortOrder(b));
        if (orderCompare != 0) return orderCompare;
        return a.name.compareTo(b.name);
      });

    return List.unmodifiable(sorted);
  }

  int _sortOrder(FmStation station) {
    if (station is FmStationModel) return station.sortOrder;
    return 0;
  }
}
