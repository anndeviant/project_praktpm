import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/prayer_model.dart';
import 'base_network.dart';

class PrayerService {
  final BaseNetwork _network = BaseNetwork();
  final Logger _logger = Logger();
  static const String _cityIdKey = 'selected_city_id';
  static const String _cityNameKey = 'selected_city_name';

  Future<List<CitySearch>> searchCity(String keyword) async {
    try {
      final response = await _network.get('/sholat/kota/cari/$keyword');

      if (response != null && response['status'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((city) => CitySearch.fromJson(city)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('Error searching city: $e');
      return [];
    }
  }

  Future<PrayerSchedule?> getPrayerSchedule(String cityId, String date) async {
    try {
      final response = await _network.get('/sholat/jadwal/$cityId/$date');

      if (response != null && response['status'] == true) {
        _logger.i('Prayer schedule response: $response');
        return PrayerSchedule.fromJson(response);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting prayer schedule: $e');
      return null;
    }
  }

  Future<PrayerSchedule?> getTodayPrayerSchedule() async {
    try {
      final cityId = await getSelectedCityId();
      if (cityId == null) return null;

      final now = DateTime.now();
      final dateString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      return await getPrayerSchedule(cityId, dateString);
    } catch (e) {
      _logger.e('Error getting today prayer schedule: $e');
      return null;
    }
  }

  Future<void> saveSelectedCity(String cityId, String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cityIdKey, cityId);
      await prefs.setString(_cityNameKey, cityName);
      _logger.i('City saved: $cityName ($cityId)');
    } catch (e) {
      _logger.e('Error saving selected city: $e');
    }
  }

  Future<String?> getSelectedCityId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_cityIdKey);
    } catch (e) {
      _logger.e('Error getting selected city ID: $e');
      return null;
    }
  }

  Future<String?> getSelectedCityName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_cityNameKey);
    } catch (e) {
      _logger.e('Error getting selected city name: $e');
      return null;
    }
  }

  Future<bool> hasSelectedCity() async {
    final cityId = await getSelectedCityId();
    return cityId != null && cityId.isNotEmpty;
  }

  Future<HijriCalendar?> getHijriCalendar() async {
    try {
      final response = await _network.getHijriCalendar();

      if (response != null && response['status'] == true) {
        _logger.i('Hijri calendar response: $response');
        return HijriCalendar.fromJson(response);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting hijri calendar: $e');
      return null;
    }
  }

  Future<RandomDua?> getRandomDoa() async {
    try {
      final response = await _network.getRandomDoa();

      if (response != null && response['status'] == true) {
        _logger.i('Random doa response: $response');
        return RandomDua.fromJson(response);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting random doa: $e');
      return null;
    }
  }

  Future<RandomAsmaul?> getRandomAsmaul() async {
    try {
      final response = await _network.getRandomAsmaul();

      if (response != null && response['status'] == true) {
        _logger.i('Random asmaul response: $response');
        return RandomAsmaul.fromJson(response);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting random asmaul: $e');
      return null;
    }
  }
}
