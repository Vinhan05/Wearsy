import 'dart:convert';
import 'package:http/http.dart' as http;
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

  /// Tự động định vị vị trí hiện tại qua IP mạng
  static Future<CityLocation> detectCurrentLocation() async {
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final String city = data['city'] ?? 'Vị trí của bạn';
          final double lat = (data['lat'] as num).toDouble();
          final double lon = (data['lon'] as num).toDouble();
          return CityLocation(
            name: city,
            lat: lat,
            lon: lon,
            region: 'Vị trí hiện tại (GPS/IP)',
            icon: '📍',
          );
        }
      }
    } catch (_) {
      // Fallback nếu không định vị được
    }
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
