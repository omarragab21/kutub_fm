import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/fm_station_model.dart';

class FirebaseFmRadioDataSource {
  FirebaseFmRadioDataSource({
    FirebaseFirestore? firestore,
    List<String> collectionPaths = const [
      'radioStations',
      'radio_stations',
      'fmStations',
      'fm_stations',
      'fmRadioStations',
      'fm_radio_stations',
      'radios',
      'radio',
      'stations',
    ],
    List<String> collectionGroupIds = const [
      'radioStations',
      'radio_stations',
      'fmStations',
      'fm_stations',
      'stations',
    ],
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _collectionPaths = collectionPaths,
       _collectionGroupIds = collectionGroupIds;

  final FirebaseFirestore _firestore;
  final List<String> _collectionPaths;
  final List<String> _collectionGroupIds;

  Future<List<FmStationModel>> fetchStations() async {
    final stations = <FmStationModel>[];

    for (final path in _collectionPaths) {
      final snapshot = await _firestore.collection(path).limit(100).get();
      if (snapshot.docs.isEmpty) continue;

      final parsed = _parseDocuments(snapshot.docs, sourceName: path);

      debugPrint(
        'FM Radio Firebase collection "$path": '
        '${snapshot.docs.length} docs, ${parsed.length} playable stations',
      );

      stations.addAll(parsed);
    }

    for (final collectionId in _collectionGroupIds) {
      final snapshot = await _firestore
          .collectionGroup(collectionId)
          .limit(100)
          .get();
      if (snapshot.docs.isEmpty) continue;

      final sourceName = 'collectionGroup($collectionId)';
      final parsed = _parseDocuments(snapshot.docs, sourceName: sourceName);

      debugPrint(
        'FM Radio Firebase collectionGroup "$collectionId": '
        '${snapshot.docs.length} docs, ${parsed.length} playable stations',
      );

      stations.addAll(parsed);
    }

    return List.unmodifiable(_dedupeById(stations));
  }

  List<FmStationModel> _dedupeById(List<FmStationModel> stations) {
    final byId = <String, FmStationModel>{};
    for (final station in stations) {
      byId[station.id] = station;
    }
    return byId.values.toList(growable: false);
  }

  List<FmStationModel> _parseDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String sourceName,
  }) {
    final stations = <FmStationModel>[];

    for (final doc in docs) {
      stations.addAll(_parseDocument(doc));
    }

    return stations
        .where((station) {
          final accepted = station.isActive && station.hasPlayableStream;
          if (!accepted) {
            debugPrint(
              'FM Radio skipped ${station.id} from $sourceName: '
              'isActive=${station.isActive}, '
              'hasPlayableStream=${station.hasPlayableStream}',
            );
          }
          return accepted;
        })
        .toList(growable: false);
  }

  List<FmStationModel> _parseDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final nestedStations = data['stations'];

    if (nestedStations is List) {
      return nestedStations.indexed
          .where((entry) => entry.$2 is Map)
          .map(
            (entry) => FmStationModel.fromMap(
              Map<String, dynamic>.from(entry.$2 as Map),
              fallbackId: '${doc.id}_${entry.$1}',
            ),
          )
          .toList(growable: false);
    }

    return [FmStationModel.fromFirestore(doc)];
  }
}
