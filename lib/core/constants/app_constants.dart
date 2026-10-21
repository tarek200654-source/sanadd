/// ثوابت التطبيق
abstract final class AppConstants {
  static const String appName = 'SANAD';
  static const String appTagline =
      'Context-aware care for patients and their families';
  static const String splashRoute = '/';
  static const String imuSensor = 'IMU';
  static const String barometerSensor = 'Barometer';
  static const String ppgSensor = 'PPG';
  static const String emergencyMedicalIdRoute = '/emergency-medical-id';

  // ===== ألوان الخطوط =====
  static const String line1Color = '#FF0000'; // أحمر
  static const String line2Color = '#0066CC'; // أزرق
  static const String line3Color = '#00AA00'; // أخضر

  // ===== أسماء الخطوط =====
  static const String line1Name = 'الخط الأول';
  static const String line2Name = 'الخط الثاني';
  static const String line3Name = 'الخط الثالث';

  // ===== أسعار التذاكر =====
  static const double fare1To9 = 8.0; // 1-9 محطات
  static const double fare10To16 = 10.0; // 10-16 محطة
  static const double fare17To23 = 15.0; // 17-23 محطة
  static const double fare24Plus = 20.0; // 24+ محطة

  // ===== أوقات الرحلة =====
  static const int timePerStation = 2; // دقائق لكل محطة
  static const int timePerTransfer = 4; // دقائق لكل تبديل

  // ===== رسائل النظام =====
  static const String errorStationNotFound = 'محطة غير موجودة';
  static const String errorNoRoute = 'لا يوجد مسار للرحلة';
  static const String errorNoInterchange = 'لا توجد محطات تبديل';
  static const String errorSameStation = 'أنت بالفعل في المحطة المطلوبة';

  // ===== رسائل النجاح =====
  static const String successRouteFound = 'تم العثور على المسار';
  static const String successJourneyCalculated = 'تم حساب الرحلة بنجاح';

  // ===== رسائل التوجيه =====
  static const String directionNorth = 'اتجاه الشمال';
  static const String directionSouth = 'اتجاه الجنوب';
  static const String directionEast = 'اتجاه الشرق';
  static const String directionWest = 'اتجاه الغرب';

  // ===== رسائل التبديل =====
  static const String transferMessage = 'هتنزل تبدل من محطة';
  static const String transferToLine = 'لخط';
  static const String transferDirection = 'في اتجاه';

  // ===== رسائل الركوب =====
  static const String boardingMessage = 'هتركب من محطة';
  static const String destinationMessage = 'توصل لمحطة';

  // ===== أسماء محطات التبديل الرئيسية =====
  static const String interchangeSadat = 'السادات';
  static const String interchangeShohada = 'الشهداء';
  static const String interchangeGamalAbdelNasser = 'جمال عبد الناصر';
  static const String interchangeAtaba = 'العتبة';
  static const String interchangeCairoUniversity = 'جامعة القاهرة';

  // ===== حدود البحث =====
  static const int maxSearchResults = 20;
  static const int minSearchQueryLength = 2;

  // ===== حدود الخريطة =====
  static const double defaultLatitude = 30.0444; // القاهرة
  static const double defaultLongitude = 31.2357;
  static const double mapZoomLevel = 12.0;

  // ===== أحجام العناصر =====
  static const double stationCardHeight = 80.0;
  static const double stationCardWidth = double.infinity;
  static const double lineIndicatorSize = 16.0;
  static const double stationIconSize = 24.0;

  // ===== مسافات التباعد =====
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  // ===== أحجام الخطوط =====
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 16.0;
  static const double extraLargeFontSize = 18.0;
  static const double titleFontSize = 20.0;
  static const double headingFontSize = 24.0;

  // ===== أزمنة الرسوم المتحركة =====
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // ===== أزمنة التأخير =====
  static const Duration shortDelay = Duration(milliseconds: 100);
  static const Duration mediumDelay = Duration(milliseconds: 300);
  static const Duration longDelay = Duration(milliseconds: 1000);

  // ===== أحجام الصور =====
  static const double logoSize = 48.0;
  static const double avatarSize = 40.0;
  static const double bannerHeight = 200.0;

  // ===== حدود التطبيق =====
  static const int maxRecentSearches = 10;
  static const int maxFavoriteStations = 20;
  static const int maxRouteHistory = 50;

  // ===== مفاتيح التخزين =====
  static const String keyFirstTime = 'firstTime';
  static const String keyRecentSearches = 'recentSearches';
  static const String keyFavoriteStations = 'favoriteStations';
  static const String keyRouteHistory = 'routeHistory';
  static const String keyUserPreferences = 'userPreferences';

  // ===== قيم افتراضية =====
  static const String defaultGreeting = 'مرحباً بك';
  static const String defaultStation = 'اختر المحطة';
  static const String defaultLine = 'جميع الخطوط';

  // ===== أنماط التصميم =====
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double buttonHeight = 48.0;
  static const double inputFieldHeight = 56.0;

  // ===== ألوان النظام =====
  static const String primaryColor = '#FF0000'; // أحمر المترو
  static const String secondaryColor = '#0066CC'; // أزرق
  static const String accentColor = '#00AA00'; // أخضر
  static const String backgroundColor = '#FFFFFF'; // أبيض
  static const String surfaceColor = '#F5F5F5'; // رمادي فاتح
  static const String textColor = '#000000'; // أسود
  static const String textLightColor = '#666666'; // رمادي
  static const String errorColor = '#FF0000'; // أحمر خطأ
  static const String successColor = '#00AA00'; // أخضر نجاح
  static const String warningColor = '#FFA500'; // برتقالي تحذير
  static const String infoColor = '#0066CC'; // أزرق معلومات
}
