import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/fm_station.dart';
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

    if (stations.isEmpty) {
      debugPrint('FM Radio: No stations found in Firebase, fallback to default Kutub FM station');
      return [defaultKutubFmStation];
    }

    final deduped = _dedupeById(stations);
    return List.unmodifiable(deduped);
  }

  static final FmStationModel defaultKutubFmStation = FmStationModel(
    id: 'kutub_fm_radio',
    name: 'إذاعة كُتب FM',
    tagline: 'بث مباشر إذاعة كُتب FM 98.8',
    frequencyMhz: 98.8,
    streamUrl:
        'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
    coverImageUrl:
        'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800',
    isActive: true,
    isQuranStation: false,
    sortOrder: 0,
    programs: const [
      RadioProgram(
        id: 'program_modern_communication',
        title: 'برنامج التواصل في العصر الحديث',
        audios: [
          RadioAudio(
            id: 'audio_rain',
            title: 'A Day Without Rain',
            url:
                'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
            subtitle: 'قبل يومين',
          ),
          RadioAudio(
            id: 'audio_dark_knight',
            title: 'Why So Serious / Like A Dog Chasing Cars',
            url:
                'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/hans_zimmer_dark_knight.mp3',
            subtitle: 'منذ ساعة',
          ),
          RadioAudio(
            id: 'audio_ai',
            title: 'الذكاء الاصطناعي في حياتنا',
            url:
                'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
            subtitle: 'قبل 3 ساعات',
          ),
          RadioAudio(
            id: 'audio_nature',
            title: 'العودة إلى الطبيعة',
            url:
                'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/hans_zimmer_dark_knight.mp3',
            subtitle: 'أمس',
          ),
        ],
      ),
      RadioProgram(
        id: 'program_food_industry',
        title: 'برنامج صناعة الغذاء',
        audios: [
          RadioAudio(
            id: 'audio_flavors',
            title: 'رحلة النكهات: اكتشاف أسرار الطهي التقليدي',
            url:
                'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
            subtitle: 'أسبوع مضى',
          ),
          RadioAudio(
            id: 'audio_future_table',
            title: 'مائدة المستقبل: تقنيات غذائية تغير العالم',
            url:
                'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/hans_zimmer_dark_knight.mp3',
            subtitle: 'منذ 3 أيام',
          ),
          RadioAudio(
            id: 'audio_farm_stories',
            title: 'قصص مزارع: من الحقل إلى المائدة',
            url:
                'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
            subtitle: 'أمس',
          ),
          RadioAudio(
            id: 'audio_sustainable_food',
            title: 'الغذاء المستدام: كيف نحمي كوكبنا؟',
            url:
                'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/hans_zimmer_dark_knight.mp3',
            subtitle: 'منذ 4 أيام',
          ),
          RadioAudio(
            id: 'audio_popular_food',
            title: 'تاريخ الأطعمة الشعبية: بين الأصالة والحداثة',
            url:
                'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
            subtitle: 'قبل أسبوع',
          ),
        ],
      ),
    ],
  );


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
