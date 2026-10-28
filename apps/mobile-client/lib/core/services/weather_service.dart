import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../mock/mock_data_service.dart';

class CityLocation {
  final String name;
  final double lat;
  final double lon;
  final String region;
  final String icon;

  const CityLocation({
    required this.name,
    required this.lat,
    required this.lon,
    required this.region,
    required this.icon,
  });
}

class WeatherData {
  final double temperature;
  final int humidity;
  final String condition;
  final String icon;
  final String location;
  final String suggestion;
  final String outfitFormula;
  final List<String> suggestedItems;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.icon,
    required this.location,
    required this.suggestion,
    required this.outfitFormula,
    required this.suggestedItems,
  });

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature.round(),
      'humidity': humidity,
      'condition': condition,
      'icon': icon,
      'location': location,
      'suggestion': suggestion,
      'outfitFormula': outfitFormula,
      'suggestedItems': suggestedItems,
    };
  }
}

class WeatherService {
  static const String _prefCityKey = 'cached_weather_city_name';
  static const String _prefLatKey = 'cached_weather_lat';
  static const String _prefLonKey = 'cached_weather_lon';
  static const String _prefRegionKey = 'cached_weather_region';

  // Danh sách các thành phố phổ biến tại Việt Nam
  static const List<CityLocation> popularCities = [
    CityLocation(
      name: 'TP. Hồ Chí Minh',
      lat: 10.8231,
      lon: 106.6297,
      region: 'Miền Nam',
      icon: '🏙️',
    ),
    CityLocation(
      name: 'Hà Nội',
      lat: 21.0285,
      lon: 105.8542,
      region: 'Miền Bắc',
      icon: '🏛️',
    ),
    CityLocation(
      name: 'Đà Lạt',
      lat: 11.9404,
      lon: 108.4583,
      region: 'Tây Nguyên (Se lạnh)',
      icon: '🌲',
    ),
    CityLocation(
      name: 'Đà Nẵng',
      lat: 16.0544,
      lon: 108.2022,
      region: 'Miền Trung',
      icon: '🌉',
    ),
    CityLocation(
      name: 'Nha Trang',
      lat: 12.2388,
      lon: 109.1967,
      region: 'Ven biển Nam Trung Bộ',
      icon: '🏖️',
    ),
    CityLocation(
      name: 'Sa Pa',
      lat: 22.3364,
      lon: 103.8438,
      region: 'Vùng núi Tây Bắc (Lạnh)',
      icon: '⛰️',
    ),
    CityLocation(
      name: 'Cần Thơ',
      lat: 10.0452,
      lon: 105.7469,
      region: 'Miền Tây',
      icon: '🛶',
    ),
  ];

  static final CityLocation defaultCity = popularCities[0];

  /// Lưu vị trí người dùng đã chọn vào Local Storage
  static Future<void> saveSelectedLocation(CityLocation city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefCityKey, city.name);
      await prefs.setDouble(_prefLatKey, city.lat);
      await prefs.setDouble(_prefLonKey, city.lon);
      await prefs.setString(_prefRegionKey, city.region);
    } catch (_) {}
  }

  /// Lấy vị trí đã lưu trước đó nếu có
  static Future<CityLocation?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_prefCityKey);
      final lat = prefs.getDouble(_prefLatKey);
      final lon = prefs.getDouble(_prefLonKey);
      final region = prefs.getString(_prefRegionKey);
      if (name != null && lat != null && lon != null) {
        return CityLocation(
          name: name,
          lat: lat,
          lon: lon,
          region: region ?? 'Vị trí đã lưu',
          icon: '📍',
        );
      }
    } catch (_) {}
    return null;
  }

  static String _formatCityName(String rawCity) {
    final lower = rawCity.toLowerCase().trim();
    if (lower.contains('ho chi minh') ||
        lower.contains('hồ chí minh') ||
        lower.contains('saigon') ||
        lower.contains('sài gòn')) {
      return 'TP. Hồ Chí Minh';
    }
    if (lower.contains('hanoi') ||
        lower.contains('ha noi') ||
        lower.contains('hà nội')) {
      return 'Hà Nội';
    }
    if (lower.contains('da nang') || lower.contains('đà nẵng')) {
      return 'Đà Nẵng';
    }
    if (lower.contains('da lat') || lower.contains('đà lạt')) {
      return 'Đà Lạt';
    }
    if (lower.contains('can tho') || lower.contains('cần thơ')) {
      return 'Cần Thơ';
    }
    if (lower.contains('nha trang')) {
      return 'Nha Trang';
    }
    if (lower.contains('hai phong') || lower.contains('hải phòng')) {
      return 'Hải Phòng';
    }
    if (lower.contains('vung tau') || lower.contains('vũng tàu')) {
      return 'Vũng Tàu';
    }
    if (lower.contains('hue') || lower.contains('huế')) {
      return 'Huế';
    }
    if (lower.contains('long xuyen') || lower.contains('long xuyên')) {
      return 'Long Xuyên';
    }
    return rawCity;
  }

  /// Tính khoảng cách Haversine (km) giữa 2 toạ độ GPS
  static double _calculateDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Khớp với thành phố lớn gần nhất nếu khoảng cách < 50km
  static String _matchNearestPopularCity(double lat, double lon) {
    CityLocation? closest;
    double minDistance = double.infinity;

    for (final city in popularCities) {
      final d = _calculateDistanceKm(lat, lon, city.lat, city.lon);
      if (d < minDistance) {
        minDistance = d;
        closest = city;
      }
    }

    if (closest != null && minDistance <= 55.0) {
      return closest.name;
    }
    return 'Vị trí hiện tại';
  }

  /// Lấy vị trí qua GPS phần cứng thiết bị (chính xác như Google Maps)
  static Future<CityLocation?> _detectGpsLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[WeatherService] Location services are disabled on device.');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[WeatherService] User denied location permission.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            '[WeatherService] Location permissions permanently denied.');
        return null;
      }

      // Đọc toạ độ GPS vệ tinh thời gian thực
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 7),
      );

      final double lat = position.latitude;
      final double lon = position.longitude;
      debugPrint('[WeatherService] GPS Success: $lat, $lon');

      // Reverse geocode to get city name
      String cityName = '';
      try {
        final reverseUrl = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=vi',
        );
        final res = await http.get(reverseUrl).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          cityName = (data['city'] ??
                  data['principalSubdivision'] ??
                  data['locality'] ??
                  '')
              .toString();
        }
      } catch (e) {
        debugPrint('[WeatherService] Reverse geocode error: $e');
      }

      if (cityName.isEmpty) {
        cityName = _matchNearestPopularCity(lat, lon);
      } else {
        cityName = _formatCityName(cityName);
      }

      return CityLocation(
        name: cityName,
        lat: lat,
        lon: lon,
        region: 'Vị trí GPS vệ tinh chính xác 🛰️',
        icon: '📍',
      );
    } catch (e) {
      debugPrint('[WeatherService] _detectGpsLocation exception: $e');
      return null;
    }
  }

  /// Lấy vị trí qua IP mạng (fallback khi không có GPS)
  static Future<CityLocation?> _detectIpLocation() async {
    // 1. Thử service ipwho.is (HTTPS, miễn phí)
    try {
      final response = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final String rawCity =
              data['city'] ?? data['region'] ?? 'Vị trí của bạn';
          final double lat = (data['latitude'] as num).toDouble();
          final double lon = (data['longitude'] as num).toDouble();
          return CityLocation(
            name: _formatCityName(rawCity),
            lat: lat,
            lon: lon,
            region: 'Vị trí mạng IP',
            icon: '📍',
          );
        }
      }
    } catch (_) {}

    // 2. Fallback try ipapi.co
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['city'] != null) {
          final String rawCity = data['city'];
          final double lat = (data['latitude'] as num).toDouble();
          final double lon = (data['longitude'] as num).toDouble();
          return CityLocation(
            name: _formatCityName(rawCity),
            lat: lat,
            lon: lon,
            region: 'Vị trí mạng IP',
            icon: '📍',
          );
        }
      }
    } catch (_) {}

    return null;
  }

  /// Tự động định vị: Ưu tiên GPS vệ tinh thật -> Fallback IP mạng -> Fallback Cache đã lưu
  static Future<CityLocation> detectCurrentLocation({bool forceGps = true}) async {
    if (forceGps) {
      final gpsLocation = await _detectGpsLocation();
      if (gpsLocation != null) {
        await saveSelectedLocation(gpsLocation);
        return gpsLocation;
      }
    }

    final ipLocation = await _detectIpLocation();
    if (ipLocation != null) {
      await saveSelectedLocation(ipLocation);
      return ipLocation;
    }

    final cached = await getCachedLocation();
    if (cached != null) return cached;

    return defaultCity;
  }

  /// Lấy thời tiết thời gian thực từ Open-Meteo API
  static Future<WeatherData> fetchRealtimeWeather({
    double lat = 10.8231,
    double lon = 106.6297,
    String locationName = 'TP. Hồ Chí Minh',
  }) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code&timezone=Asia%2FBangkok',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];

        final double temp = (current['temperature_2m'] as num).toDouble();
        final int humidity = (current['relative_humidity_2m'] as num).toInt();
        final int weatherCode = (current['weather_code'] as num).toInt();

        final parsedInfo = _parseWmoCode(weatherCode, temp, locationName);

        return WeatherData(
          temperature: temp,
          humidity: humidity,
          condition: parsedInfo['condition'] as String,
          icon: parsedInfo['icon'] as String,
          location: locationName,
          suggestion: parsedInfo['suggestion'] as String,
          outfitFormula: parsedInfo['outfitFormula'] as String,
          suggestedItems: parsedInfo['suggestedItems'] as List<String>,
        );
      }
    } catch (_) {
      // Fallback nếu mạng lỗi
    }

    final mock = MockDataService.getMockWeather();
    return WeatherData(
      temperature: (mock['temperature'] as num).toDouble(),
      humidity: (mock['humidity'] as num).toInt(),
      condition: mock['condition'] as String,
      icon: mock['icon'] as String,
      location: locationName,
      suggestion: mock['suggestion'] as String,
      outfitFormula: 'Sơ mi trắng + Quần tây + Blazer Beige thanh lịch',
      suggestedItems: const ['Sơ mi trắng', 'Quần tây đen', 'Blazer Beige'],
    );
  }

  /// Phân tích WMO Weather Code và sinh gợi ý phối đồ AI chi tiết
  static Map<String, dynamic> _parseWmoCode(
      int code, double temp, String location) {
    String condition;
    String icon;
    String suggestion;
    String formula;
    List<String> items;

    // Phân tích kịch bản lạnh (< 21°C - đặc trưng Đà Lạt, Sa Pa, Hà Nội mùa đông)
    if (temp <= 20) {
      condition = temp < 15 ? 'Rét buốt' : 'Se lạnh';
      icon = temp < 15 ? '❄️' : '🧥';
      suggestion =
          'Không khí se lạnh vùng $location, thời điểm tuyệt vời cho phong cách thu đông nhiều lớp (layering) sang trọng.';
      formula =
          'Áo len dệt kim cổ lọ + Áo khoác dạ dáng dài / Trench Coat + Quần âu ống suông + Giày da / Chelsea Boots';
      items = [
        'Áo len cổ lọ',
        'Áo dạ dáng dài',
        'Quần âu ống suông',
        'Boots da'
      ];
    }
    // Phân tích kịch bản mưa (WMO 51-65, 80-82, 95-99)
    else if ((code >= 51 && code <= 65) || (code >= 80 && code <= 99)) {
      final isHeavy = (code >= 63 && code <= 65) || code >= 95;
      condition = isHeavy ? 'Mưa to / Dông' : 'Trời mưa';
      icon = isHeavy ? '⛈️' : '🌧️';
      suggestion =
          'Thời tiết có mưa tại $location. Hãy ưu tiên trang phục nhanh khô, quần tối màu chống bẩn và mang theo ô/áo mưa.';
      formula =
          'Áo khoác gió trượt nước (Windbreaker) + Quần cropped tối màu + Sneaker da / Giày chống thấm';
      items = [
        'Áo khoác gió',
        'Quần cropped đen',
        'Sneaker chống nước',
        'Ô gấp'
      ];
    }
    // Phân tích kịch bản nắng gắt (> 30°C - đặc trưng TP.HCM, Nha Trang ban ngày)
    else if (temp >= 31) {
      condition = 'Nắng nóng';
      icon = '☀️';
      suggestion =
          'Nhiệt độ cao ($temp°C), hãy chọn trang phục chất liệu thoáng khí, chống tia UV để luôn tự tin và mát mẻ.';
      formula =
          'Sơ mi cộc tay Linen / Đũi thoáng mát + Quần shorts chinos / Đũi ống rộng + Kính râm thời thượng';
      items = ['Sơ mi Linen', 'Quần đũi mát', 'Kính râm UV', 'Mũ cói'];
    }
    // Phân tích kịch bản mát mẻ dễ chịu (21°C - 30°C)
    else {
      condition = (code == 1 || code == 2 || code == 3)
          ? 'Nắng nhẹ, có mây'
          : 'Mát mẻ dễ chịu';
      icon = '⛅';
      suggestion =
          'Thời tiết $location hôm nay rất đẹp ($temp°C), hoàn hảo cho mọi phong cách dạo phố, công sở hoặc cà phê cuối tuần.';
      formula =
          'Áo thun cotton cao cấp + Áo sơ mi flannel/oversize khoác ngoài + Quần jeans slim-fit + Giày retro sneaker';
      items = [
        'Áo thun cotton',
        'Sơ mi khoác ngoài',
        'Quần jeans',
        'Retro sneaker'
      ];
    }

    return {
      'condition': condition,
      'icon': icon,
      'suggestion': suggestion,
      'outfitFormula': formula,
      'suggestedItems': items,
    };
  }
}
