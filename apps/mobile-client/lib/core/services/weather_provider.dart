import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/language_provider.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/tag_localization.dart';
import 'weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherData? _weatherData;
  CityLocation _selectedCity = WeatherService.defaultCity;
  bool _isLoading = false;

  WeatherData? get weatherData => _weatherData;
  CityLocation get selectedCity => _selectedCity;
  bool get isLoading => _isLoading;

  String get temperatureString =>
      _weatherData != null ? '${_weatherData!.temperature.round()}°C' : '29°C';

  String get cityName => _selectedCity.name;

  WeatherProvider() {
    initWeather();
  }

  Future<void> initWeather() async {
    _isLoading = true;
    notifyListeners();
    try {
      final cached = await WeatherService.getCachedLocation();
      final targetCity =
          cached ?? await WeatherService.detectCurrentLocation(forceGps: true);
      _selectedCity = targetCity;
      _weatherData = await WeatherService.fetchRealtimeWeather(
        lat: targetCity.lat,
        lon: targetCity.lon,
        locationName: targetCity.name,
      );
    } catch (e) {
      debugPrint('[WeatherProvider] Error initializing weather: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeather([CityLocation? city]) async {
    _isLoading = true;
    notifyListeners();
    try {
      CityLocation targetCity;
      if (city != null) {
        targetCity = city;
        await WeatherService.saveSelectedLocation(city);
      } else {
        targetCity = await WeatherService.detectCurrentLocation(forceGps: true);
      }
      _selectedCity = targetCity;
      final data = await WeatherService.fetchRealtimeWeather(
        lat: targetCity.lat,
        lon: targetCity.lon,
        locationName: targetCity.name,
      );
      _weatherData = data;
    } catch (e) {
      debugPrint('[WeatherProvider] Error fetching weather: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static void showCityPickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isEn = Provider.of<LanguageProvider>(ctx).isEnglish;
        final weatherProv = Provider.of<WeatherProvider>(ctx);
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEn
                    ? 'Select Weather Location 📍'
                    : 'Chọn Vị Trí Thời Tiết 📍',
                style: AppFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: const Text('🛰️', style: TextStyle(fontSize: 24)),
                title: Text(
                  isEn
                      ? 'Current Location (Auto Detect)'
                      : 'Vị trí hiện tại (Định vị tự động)',
                  style: AppFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                subtitle: Text(
                  isEn
                      ? 'Direct GPS satellite (Google Maps accuracy)'
                      : 'Định vị GPS vệ tinh chuẩn xác như Google Maps',
                  style: AppFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  weatherProv.fetchWeather(null);
                },
              ),
              const Divider(color: Colors.black12, height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: WeatherService.popularCities.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.black12, height: 1),
                  itemBuilder: (context, index) {
                    final city = WeatherService.popularCities[index];
                    final isSelected =
                        city.name == weatherProv.selectedCity.name;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading:
                          Text(city.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        TagLocalization.getLocalizedCityName(city.name, isEn),
                        style: AppFonts.inter(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryLight
                              : const Color(0xFF111827),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: AppTheme.primaryLight)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        weatherProv.fetchWeather(city);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

